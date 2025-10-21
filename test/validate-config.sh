#!/usr/bin/env bash
#
# validate-config.sh - Validates .claude configuration structure and content
#
# Usage: ./test/validate-config.sh [CONFIG_DIR]
#   CONFIG_DIR defaults to current directory
#
# Exit codes:
#   0 - All validations passed
#   1 - One or more validations failed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
FAIL_COUNT=0

# Default to current directory
CONFIG_DIR="${1:-.}"

# Helper functions
pass() {
  echo -e "${GREEN}✓${NC} $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

info() {
  echo "ℹ $1"
}

# Validation functions

validate_directory_structure() {
  info "Validating directory structure..."

  if [[ -d "$CONFIG_DIR/commands" ]]; then
    pass "commands/ directory exists"
  else
    fail "commands/ directory is missing"
  fi

  if [[ -d "$CONFIG_DIR/hooks" ]]; then
    pass "hooks/ directory exists"
  else
    fail "hooks/ directory is missing"
  fi

  # Optional directories
  if [[ -d "$CONFIG_DIR/agents" ]]; then
    pass "agents/ directory exists (optional)"
  fi

  if [[ -d "$CONFIG_DIR/skills" ]]; then
    pass "skills/ directory exists (optional)"
  fi
}

validate_settings_json() {
  info "Validating settings.json..."

  if [[ -f "$CONFIG_DIR/settings.json" ]]; then
    pass "settings.json exists"

    # Validate JSON syntax
    if jq empty "$CONFIG_DIR/settings.json" 2>/dev/null; then
      pass "settings.json is valid JSON"
    else
      fail "settings.json contains invalid JSON syntax"
      return
    fi

    # Check for hooks configuration
    if jq -e '.hooks' "$CONFIG_DIR/settings.json" >/dev/null 2>&1; then
      pass "settings.json contains hooks configuration"

      # Validate hook references
      local hook_commands
      hook_commands=$(jq -r '.. | .command? // empty' "$CONFIG_DIR/settings.json" 2>/dev/null || echo "")

      if [[ -n "$hook_commands" ]]; then
        while IFS= read -r hook_cmd; do
          # Skip empty lines
          [[ -z "$hook_cmd" ]] && continue

          # Extract script path from command (handle quoted paths and $CLAUDE_PROJECT_DIR)
          local script_path
          script_path=$(echo "$hook_cmd" | sed -E 's/.*\$CLAUDE_PROJECT_DIR.?\/?(.+\.sh).*/\1/' | sed 's/"//g')

          if [[ "$script_path" != "$hook_cmd" && "$script_path" =~ \.sh$ ]]; then
            # Found a hook script reference
            # Try full path first, then try removing .claude/ prefix for source repos
            local full_path="$CONFIG_DIR/$script_path"
            local alt_path="${script_path#.claude/}"
            local alt_full_path="$CONFIG_DIR/$alt_path"

            if [[ -f "$full_path" ]]; then
              pass "Hook script exists: $script_path"
            elif [[ -f "$alt_full_path" ]]; then
              pass "Hook script exists: $alt_path (will be installed to $script_path)"
            else
              fail "Hook script missing: $script_path (referenced in settings.json)"
            fi
          fi
        done <<< "$hook_commands"
      fi
    else
      warn "settings.json does not define hooks (optional)"
    fi

    # Check for permissions
    if jq -e '.permissions' "$CONFIG_DIR/settings.json" >/dev/null 2>&1; then
      pass "settings.json contains permissions configuration"
    else
      warn "settings.json does not define permissions (optional)"
    fi

  else
    warn "settings.json not found (optional for project-level config)"
  fi
}

validate_hook_scripts() {
  info "Validating hook scripts..."

  if [[ ! -d "$CONFIG_DIR/hooks" ]]; then
    return
  fi

  local hook_count=0

  # Find all .sh files in hooks directory
  while IFS= read -r -d '' script; do
    ((hook_count++))
    local script_name
    script_name=$(basename "$script")

    # Check if executable
    if [[ -x "$script" ]]; then
      pass "Hook script is executable: $script_name"
    else
      fail "Hook script is not executable: $script_name (run: chmod +x $script)"
    fi

    # Check for proper response format in pre-hooks
    if [[ "$script_name" == pre_* ]]; then
      if grep -q '{"decision":' "$script" || grep -q '"approve"' "$script" || grep -q '"block"' "$script"; then
        pass "Pre-hook uses correct response format: $script_name"
      else
        warn "Pre-hook may not use correct response format: $script_name (should output {\"decision\": \"approve\"} or {\"decision\": \"block\"})"
      fi
    fi

    # Check shebang
    local first_line
    first_line=$(head -n 1 "$script")
    if [[ "$first_line" =~ ^#!.*bash ]]; then
      pass "Hook has valid bash shebang: $script_name"
    else
      warn "Hook missing bash shebang: $script_name"
    fi

  done < <(find "$CONFIG_DIR/hooks" -name "*.sh" -print0)

  if [[ $hook_count -eq 0 ]]; then
    warn "No hook scripts (.sh files) found in hooks/ directory"
  fi
}

validate_command_files() {
  info "Validating command files..."

  if [[ ! -d "$CONFIG_DIR/commands" ]]; then
    return
  fi

  local cmd_count=0

  # Find all .md files in commands directory
  while IFS= read -r -d '' cmd_file; do
    ((cmd_count++))
    local cmd_name
    cmd_name=$(basename "$cmd_file")

    # Check for frontmatter
    if head -n 1 "$cmd_file" | grep -q '^---$'; then
      pass "Command has frontmatter: $cmd_name"

      # Extract frontmatter (between first and second ---)
      local frontmatter
      frontmatter=$(awk '/^---$/{if(++n==2)exit;next}n==1' "$cmd_file")

      # Check for required fields
      if echo "$frontmatter" | grep -q '^description:'; then
        pass "Command has description field: $cmd_name"
      else
        fail "Command missing description field: $cmd_name"
      fi

      # Check for model field (optional but recommended)
      if echo "$frontmatter" | grep -q '^model:'; then
        local model_id
        model_id=$(echo "$frontmatter" | grep '^model:' | sed 's/^model:[[:space:]]*//')

        # Validate model ID format (claude-sonnet-*, claude-haiku-*, claude-opus-*, claude-3-5-sonnet-*)
        if [[ "$model_id" =~ ^claude-([0-9]+-[0-9]+-)?((sonnet|haiku|opus)-|v[0-9]+) ]]; then
          pass "Command has valid model ID: $cmd_name ($model_id)"
        else
          warn "Command has potentially invalid model ID: $cmd_name ($model_id)"
        fi
      fi

      # Check for allowed-tools field (optional but recommended)
      if echo "$frontmatter" | grep -q '^allowed-tools:'; then
        pass "Command has allowed-tools field: $cmd_name"
      fi

    else
      fail "Command missing frontmatter: $cmd_name"
    fi

    # Check for examples section (from Option D)
    if grep -q '^## Examples' "$cmd_file"; then
      pass "Command includes Examples section: $cmd_name"
    else
      warn "Command missing Examples section: $cmd_name (recommended)"
    fi

  done < <(find "$CONFIG_DIR/commands" -name "*.md" -print0)

  if [[ $cmd_count -eq 0 ]]; then
    fail "No command files (.md files) found in commands/ directory"
  else
    pass "Found $cmd_count command file(s)"
  fi
}

validate_claude_md() {
  info "Validating CLAUDE.md..."

  if [[ -f "$CONFIG_DIR/CLAUDE.md" ]]; then
    pass "CLAUDE.md exists"

    # Check for key sections
    if grep -q '## Agent Development Flow' "$CONFIG_DIR/CLAUDE.md"; then
      pass "CLAUDE.md contains Agent Development Flow section"
    else
      warn "CLAUDE.md missing Agent Development Flow section"
    fi

    if grep -q '## Safety Guardrails' "$CONFIG_DIR/CLAUDE.md"; then
      pass "CLAUDE.md contains Safety Guardrails section"
    else
      warn "CLAUDE.md missing Safety Guardrails section"
    fi

  else
    warn "CLAUDE.md not found (recommended for project guidelines)"
  fi
}

# Main validation flow
main() {
  echo "========================================"
  echo "  Claude Config Validation"
  echo "========================================"
  echo "Config directory: $CONFIG_DIR"
  echo ""

  validate_directory_structure
  echo ""

  validate_settings_json
  echo ""

  validate_hook_scripts
  echo ""

  validate_command_files
  echo ""

  validate_claude_md
  echo ""

  echo "========================================"
  echo "  Results"
  echo "========================================"
  echo -e "${GREEN}Passed:${NC} $PASS_COUNT"
  echo -e "${RED}Failed:${NC} $FAIL_COUNT"

  if [[ $FAIL_COUNT -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ All validations passed!${NC}"
    exit 0
  else
    echo ""
    echo -e "${RED}✗ Validation failed with $FAIL_COUNT error(s)${NC}"
    exit 1
  fi
}

# Run main function
main
