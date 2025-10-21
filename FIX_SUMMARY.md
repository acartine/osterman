# Osterman .claude Configuration - Quick Fix Summary

## What's Broken?

### 1. Slash Commands Don't Exist (CRITICAL)
**Current**: Commands documented in `hooks/command_router.md`
**Problem**: This is just a markdown file. Claude Code can't execute it.
**Fix**: Create `commands/` directory with individual `.md` files for each command.

**Example**:
```
commands/
├── pe-plan.md      → enables /pe-plan
├── pe-apply.md     → enables /pe-apply
├── tl-review.md    → enables /tl-review
└── ...
```

Each file needs frontmatter + prompt body with `$ARGUMENTS` placeholder.

### 2. Hooks Are Documentation, Not Code (CRITICAL)
**Current**: Hooks are markdown files with YAML frontmatter
**Problem**: Hooks must be executable scripts that output JSON.
**Fix**: Create executable shell scripts configured in `settings.json`.

**Example**:
```bash
# hooks/pre_safety_check.sh
#!/usr/bin/env bash
INPUT=$(cat)
# ... check for dangerous commands ...
echo '{"continue": false, "stopReason": "Blocked"}'
```

Configured in `settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(terraform apply:*)",
        "hooks": [{"type": "command", "command": "hooks/pre_safety_check.sh"}]
      }
    ]
  }
}
```

### 3. Settings Configuration Incomplete (CRITICAL)
**Current**: Only has minimal permissions
**Fix**: Need full hook configuration, tool matchers, and comprehensive permissions.

## Quick Start Fixes

### Priority 1: Make Slash Commands Work

```bash
# Create commands directory
mkdir -p commands

# Create a test command
cat > commands/pe-plan.md << 'EOF'
---
description: Run Terraform plan-only and summarize risks
argument-hint: DIR=<path> [WORKSPACE=<name>]
---

You are the Production Engineering (pe) agent.

Run Terraform plan for the directory and workspace specified in: $ARGUMENTS

DO NOT run terraform apply. Only plan.
EOF
```

### Priority 2: Make Safety Hooks Work

```bash
# Create executable hook
cat > hooks/pre_safety_check.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')

if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

  if [[ "$COMMAND" =~ terraform\ apply ]]; then
    cat <<EOJ
{
  "continue": false,
  "stopReason": "terraform apply requires explicit approval",
  "systemMessage": "⚠️  Blocked: High-risk operation"
}
EOJ
    exit 0
  fi
fi

echo '{"continue": true}'
EOF

chmod +x hooks/pre_safety_check.sh
```

### Priority 3: Configure Hooks in Settings

```bash
cat > settings.json.example << 'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(terraform apply:*)",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",
            "timeout": 30000
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": ["Bash(git:*)", "Bash(terraform plan:*)", "Read", "Grep"],
    "ask": ["Bash(terraform apply:*)", "Write", "Edit"],
    "deny": []
  }
}
EOF
```

## Installation After Fixes

### For Global Use

```bash
# Backup existing config
mv ~/.claude ~/.claude.backup-$(date +%Y%m%d) 2>/dev/null || true

# Copy osterman template
cp -r /Users/cartine/osterman ~/.claude

# Make hooks executable
chmod +x ~/.claude/hooks/*.sh

# Create settings from example
cp ~/.claude/settings.json.example ~/.claude/settings.json

# Add bin to PATH
export PATH="$HOME/.claude/bin:$PATH"
```

### For Project Use

```bash
# In your project
mkdir -p .claude
cp -r /Users/cartine/osterman/commands .claude/
cp -r /Users/cartine/osterman/hooks .claude/
cp -r /Users/cartine/osterman/agents .claude/
cp /Users/cartine/osterman/settings.json.example .claude/settings.json

chmod +x .claude/hooks/*.sh
```

## Testing

```bash
# Test slash command exists
claude
# In chat: /help
# Should show /pe-plan, /tl-review, etc.

# Test hook blocks dangerous command
# In chat, try: "Run terraform apply"
# Should be blocked by pre_safety_check.sh

# Test hook script directly
echo '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | \
  hooks/pre_safety_check.sh | jq
# Should output: {"continue": false, ...}
```

## File Checklist

### Must Create (Phase 1)

- [ ] `commands/pe-plan.md`
- [ ] `commands/pe-apply.md`
- [ ] `commands/tl-review.md`
- [ ] `commands/tl-triage.md`
- [ ] `commands/swe-impl.md`
- [ ] `commands/test-health.md`
- [ ] `commands/dbg.md`
- [ ] `commands/arch-plan.md`
- [ ] `hooks/pre_safety_check.sh` (executable)
- [ ] `hooks/post_telemetry.sh` (executable)
- [ ] `settings.json.example` (complete config)

### Should Update (Phase 2)

- [ ] `commands/README.md` (explain slash commands)
- [ ] `hooks/README.md` (explain executable hooks)
- [ ] `skills/README.md` (clarify these are docs)
- [ ] `README.md` (correct installation instructions)
- [ ] `agents/*.md` (clarify skills/hooks are references)

### Can Remove (Phase 3)

- [ ] `hooks/command_router.md` (replaced by commands/)
- [ ] `hooks/*.md` except READMEs (move to docs/ or remove)

## Key Concepts

### Slash Commands
- **Location**: `commands/*.md` (when installed: `~/.claude/commands/`)
- **Format**: Markdown file with optional frontmatter
- **Invocation**: User types `/command-name args` in chat
- **Purpose**: Custom prompts with argument handling

### Hooks
- **Location**: Executable scripts, configured in `settings.json`
- **Format**: Script that reads JSON from stdin, writes JSON to stdout
- **Events**: PreToolUse (before tool runs), PostToolUse (after tool runs)
- **Purpose**: Automated guardrails, telemetry, tool input modification

### Skills
- **Location**: `skills/*.md`
- **Format**: Markdown documentation with YAML frontmatter
- **Purpose**: Patterns and workflows for agents to reference
- **Note**: NOT executable, just documentation

### Agents
- **Location**: `agents/*.md`
- **Format**: Markdown prompts with YAML frontmatter
- **Selection**: User chooses agent manually
- **Purpose**: Role-specific behavior and context

## Common Mistakes to Avoid

1. **Don't put slash commands in hooks/** - They go in `commands/`
2. **Don't make hooks as markdown files** - They must be executable scripts
3. **Don't expect skills to be callable** - They're documentation only
4. **Don't forget to chmod +x hooks/** - Scripts must be executable
5. **Don't forget settings.json** - Hooks need configuration to run
6. **Don't forget jq dependency** - Hook scripts use jq for JSON parsing

## Questions?

See `SPECIFICATION.md` for complete details, or:
- Official Hooks Docs: https://docs.claude.com/en/docs/claude-code/hooks
- Official Slash Commands Docs: https://docs.claude.com/en/docs/claude-code/slash-commands
