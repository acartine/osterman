# Osterman .claude Configuration - Implementation Plan

## Overview

This document provides an **iterative, testable implementation plan** for building the osterman .claude configuration template. Each iteration delivers working functionality that can be installed and validated before proceeding to the next iteration.

## Prerequisites

- Claude Code CLI installed
- jq installed (`brew install jq` or `apt-get install jq`)
- git, gh CLI (for GitHub-related features)
- terraform (for infrastructure features)
- Basic bash scripting knowledge

## Development Approach

This plan follows an **incremental build-test-validate** approach:

1. Build 1-3 related items per iteration
2. Install and test the iteration
3. Validate functionality before proceeding
4. Each iteration builds on the previous one
5. Working functionality at every checkpoint

## Quick Reference

| Iteration | What Gets Built | Duration | Testable? |
|-----------|----------------|----------|-----------|
| 1 | Single slash command + minimal settings | 1 hour | Yes |
| 2 | Additional slash commands (3 more) | 1.5 hours | Yes |
| 3 | Basic safety hook | 1.5 hours | Yes |
| 4 | Telemetry hook | 1 hour | Yes |
| 5 | Complete settings + permissions | 1 hour | Yes |
| 6 | Remaining slash commands (4 more) | 2 hours | Yes |
| 7 | Advanced hook features | 1.5 hours | Yes |
| 8 | Documentation | 2 hours | Yes |
| 9 | Integration testing | 1.5 hours | Yes |

---

## Iteration 1: Single Slash Command + Minimal Settings

**Goal**: Get ONE slash command working end-to-end to validate the entire setup.

**Duration**: 1 hour

**What Gets Built**:
- `commands/` directory
- Single slash command: `/test-health`
- Minimal `settings.json` (no hooks yet)

### Files to Create

#### 1. Create commands directory
```bash
cd /Users/cartine/osterman
mkdir -p commands
```

#### 2. Create test-health.md (simplest command)
```bash
cat > commands/test-health.md << 'EOF'
---
description: Generate test health report with flaky and slow test analysis
allowed-tools: Bash(make:*), Bash(npm:*), Bash(pytest:*), Read, Grep
---

# Test Engineer: Test Health Report

Analyze test suite health and identify issues.

## Instructions
1. Run test suite (prefer `make test` or similar target)
2. Analyze results for:
   - Flaky tests (inconsistent pass/fail)
   - Slow tests (>5s execution time)
   - Test coverage gaps
   - Skipped/ignored tests
3. Recommend top 5 improvements

See `skills/test_health_report.md` for analysis framework.
EOF
```

#### 3. Create minimal settings.json
```bash
cat > settings.json << 'EOF'
{
  "comment": "Minimal settings.json for Iteration 1 - Single slash command test",

  "permissions": {
    "allow": [
      "Bash(make:*)",
      "Bash(npm:*)",
      "Bash(pytest:*)",
      "Read",
      "Grep",
      "Glob"
    ]
  }
}
EOF
```

### Installation

```bash
# Backup existing config if present
if [ -d ~/.claude ]; then
  mv ~/.claude ~/.claude.backup-$(date +%Y%m%d%H%M%S)
fi

# Install Iteration 1
mkdir -p ~/.claude
cp -r commands ~/.claude/
cp settings.json ~/.claude/

# Verify installation
ls ~/.claude/commands/
# Should show: test-health.md
```

### Testing

#### Test 1: Verify command appears
```bash
# In a new terminal
claude

# In Claude Code chat:
/help
# Look for /test-health in the list
```

**Expected**: `/test-health` appears in command list with description

#### Test 2: Try the command
```
/test-health
```

**Expected**:
- Claude responds with request for more context or attempts to run tests
- No "Unknown command" error
- No permission errors for allowed tools

#### Test 3: Check settings loaded
Try using a tool that should be allowed:
```
Can you check if there's a Makefile in this project with a test target?
```

**Expected**: Claude can use `Read` and `Bash(make:*)` without asking permission

### Troubleshooting

**Problem**: `/help` doesn't show `/test-health`
- Check file exists: `ls ~/.claude/commands/test-health.md`
- Check file has `.md` extension
- Restart Claude Code
- Check frontmatter YAML is valid (no syntax errors)

**Problem**: "Permission denied" errors
- Verify `settings.json` has the `allow` list
- Check JSON syntax: `jq empty ~/.claude/settings.json`
- Restart Claude Code after settings changes

**Problem**: Command doesn't do anything
- This is expected - we don't have test infrastructure yet
- The goal is to verify the command is recognized

### QA Checkpoint

**Before proceeding to Iteration 2, verify**:
- [ ] `/help` shows `/test-health` command
- [ ] `/test-health` is recognized (no "Unknown command")
- [ ] No permission errors for basic tools
- [ ] Settings file loaded successfully

---

## Iteration 2: Add More Slash Commands

**Goal**: Add 3 more slash commands to test command variety.

**Duration**: 1.5 hours

**What Gets Built**:
- `/pe-plan` - Terraform plan command
- `/tl-review` - PR review command
- `/dbg` - Debug command

### Files to Create

#### 1. Create pe-plan.md
```bash
cat > commands/pe-plan.md << 'EOF'
---
description: Run Terraform plan-only analysis with risk summary
argument-hint: DIR=<path> [WORKSPACE=<name>]
allowed-tools: Bash(terraform:*), Bash(make:*), Bash(cd:*), Read, Grep, Glob
model: sonnet
---

# Production Engineering: Terraform Plan Analysis

You are operating as the Production Engineering (pe) agent in plan-only mode.

## Task
Run a Terraform plan operation and provide a comprehensive risk summary.

## Arguments
User provided: $ARGUMENTS

Expected format: `DIR=./infra WORKSPACE=staging`
- DIR: Directory containing Terraform files (required)
- WORKSPACE: Terraform workspace to use (optional)

## Instructions

1. **Parse Arguments**
   - Extract DIR and WORKSPACE from $ARGUMENTS
   - Validate DIR exists

2. **Environment Setup**
   - Change to the specified directory
   - Run `terraform init` if needed
   - If WORKSPACE is specified, select it with `terraform workspace select`

3. **Execute Plan**
   - Run `terraform plan` (NEVER run terraform apply)
   - Capture the full plan output for analysis

4. **Risk Analysis**
   Analyze the plan output and summarize:
   - Total resources to add/change/destroy
   - IAM & Security changes
   - Network changes
   - Data & Storage changes
   - Cost impact
   - High risk items

5. **Output Format**
   Format your response with sections:
   - Changes Overview
   - Risk Level (Critical / High / Medium / Low)
   - Key Changes
   - Recommendations
   - Next Steps

6. **Safety Guardrails**
   - NEVER run `terraform apply` under any circumstances
   - If user requests apply, respond: "terraform apply requires explicit approval. Please use `/pe-apply`"

## Reference Documentation
- **Skills**: See `skills/tf_plan_only.md` for detailed workflow
- **Agent**: See `agents/pe.md` for autonomy policy
EOF
```

#### 2. Create tl-review.md
```bash
cat > commands/tl-review.md << 'EOF'
---
description: Review pull request with structured feedback
argument-hint: REPO=<org/name> PR=<number>
allowed-tools: Bash(gh:*), Bash(git:*), Read, Grep
model: sonnet
---

# Team Lead: Pull Request Review

You are operating as the Team Lead (tl) agent for PR review.

## Task
Review a pull request and provide structured feedback.

## Arguments
User provided: $ARGUMENTS

Expected format: `REPO=org/name PR=123`
- REPO: GitHub repository in org/name format (required)
- PR: Pull request number (required)

## Instructions

1. **Fetch PR Information**
   ```bash
   gh pr view <num> --repo <org/name> --json number,title,author,mergeable,state
   gh pr diff <num> --repo <org/name>
   ```

2. **Perform Quality Review**
   Analyze changes for:
   - Correctness
   - Security
   - Performance
   - Tests
   - Documentation
   - Code Quality

3. **Categorize Findings**
   - **Critical** (must fix before merge)
   - **Important** (should fix before merge)
   - **Suggestions** (nice to have)

4. **Assess Risk Level**
   - Low Risk: <100 lines, well-tested, green CI
   - Medium Risk: 100-500 lines, some test gaps
   - High Risk: >500 lines, missing tests, red CI

5. **Output Format**
   Provide structured review with sections:
   - Summary
   - Risk Assessment
   - Findings (Critical/Important/Suggestions)
   - Merge Readiness
   - Next Steps

## Reference Documentation
- **Skills**: `skills/gh_pr_review.md`
- **Agent**: `agents/tl.md`
EOF
```

#### 3. Create dbg.md
```bash
cat > commands/dbg.md << 'EOF'
---
description: Debug runtime errors and unexpected behavior
argument-hint: <description of issue>
allowed-tools: Read, Grep, Glob, Bash(*)
---

# Debugger: Runtime Error Analysis

Diagnose and fix runtime errors or unexpected behavior.

## Arguments
User provided: $ARGUMENTS
Expected: Description of the issue, error message, or failing test name

## Instructions
1. Request stack trace or error output if not provided
2. Request reproduction steps
3. Scope relevant code
4. Analyze root cause
5. Propose fix with verification steps
6. Implement fix if approved

See `agents/code-debugger.md` for methodology.
EOF
```

#### 4. Update settings.json
```bash
cat > settings.json << 'EOF'
{
  "comment": "Settings for Iteration 2 - Multiple slash commands",

  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(make:*)",
      "Bash(npm:*)",
      "Bash(pytest:*)",
      "Bash(terraform init:*)",
      "Bash(terraform plan:*)",
      "Bash(terraform workspace:*)",
      "Read",
      "Grep",
      "Glob"
    ],
    "ask": [
      "Bash(terraform apply:*)",
      "Write",
      "Edit"
    ]
  }
}
EOF
```

### Installation

```bash
# Copy new commands
cp commands/pe-plan.md ~/.claude/commands/
cp commands/tl-review.md ~/.claude/commands/
cp commands/dbg.md ~/.claude/commands/

# Update settings
cp settings.json ~/.claude/

# Verify
ls ~/.claude/commands/
# Should show: test-health.md, pe-plan.md, tl-review.md, dbg.md
```

### Testing

#### Test 1: All commands appear
```bash
claude

# In chat:
/help
```

**Expected**: All 4 commands listed with descriptions

#### Test 2: Test /pe-plan
```
/pe-plan DIR=./some/path
```

**Expected**:
- Claude acknowledges the arguments
- Attempts to analyze directory or asks for more info
- No "Unknown command" error

#### Test 3: Test /tl-review
```
/tl-review REPO=osterman/osterman PR=1
```

**Expected**:
- Claude attempts to use `gh` command
- May ask for permission (expected, gh might need auth)
- Recognizes the command format

#### Test 4: Test /dbg
```
/dbg I'm getting a TypeError on line 42
```

**Expected**:
- Claude asks for stack trace or more context
- Offers to search codebase
- Provides debugging assistance

#### Test 5: Test permissions
Try a blocked operation:
```
Can you run terraform apply in ./infra?
```

**Expected**: Claude asks for permission or explains it needs approval

### Troubleshooting

**Problem**: Commands don't accept arguments
- Check `argument-hint` in frontmatter
- Verify $ARGUMENTS placeholder in command body
- Arguments work best when used naturally: `/pe-plan DIR=./infra`

**Problem**: Permission asked for every operation
- Check `permissions.allow` has wildcards: `Bash(git:*)`
- Not just `Bash(git)` without asterisk
- Restart Claude Code after settings changes

**Problem**: gh/terraform commands fail
- Expected if these tools aren't installed
- The goal is to verify command structure, not full execution
- Commands should still be recognized

### QA Checkpoint

**Before proceeding to Iteration 3, verify**:
- [ ] All 4 commands appear in `/help`
- [ ] Each command is recognized (no "Unknown command")
- [ ] Arguments are parsed correctly
- [ ] Permission system working (allows git/gh, asks for terraform apply)
- [ ] Commands provide appropriate responses

---

## Iteration 3: Basic Safety Hook

**Goal**: Add safety hook that blocks dangerous operations.

**Duration**: 1.5 hours

**What Gets Built**:
- `hooks/` directory
- `pre_safety_check.sh` - Blocks dangerous operations
- Updated `settings.json` with hook configuration

### Files to Create

#### 1. Create hooks directory
```bash
mkdir -p hooks
```

#### 2. Create pre_safety_check.sh
```bash
cat > hooks/pre_safety_check.sh << 'EOFHOOK'
#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook to enforce safety guardrails
# Blocks high-risk operations requiring explicit approval

# Read JSON input from stdin
INPUT=$(cat)

# Check if jq is available
if ! command -v jq &> /dev/null; then
  # Fallback: allow operation if jq not available
  echo '{"continue": true}' >&1
  exit 0
fi

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

# Function to block operation with message
block_operation() {
  local reason="$1"
  cat <<EOFJSON >&1
{
  "continue": false,
  "stopReason": "${reason}",
  "systemMessage": "⚠️  BLOCKED: ${reason}"
}
EOFJSON
  exit 0
}

# Function to allow operation
allow_operation() {
  echo '{"continue": true}' >&1
  exit 0
}

# Safety checks based on tool type
case "$TOOL_NAME" in
  "Bash")
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

    # Terraform apply - always block
    if [[ "$COMMAND" =~ terraform[[:space:]]+apply ]]; then
      block_operation "terraform apply requires explicit approval via /pe-apply command"
    fi

    # Kubectl apply/delete in non-kind contexts
    if [[ "$COMMAND" =~ kubectl[[:space:]]+(apply|delete) ]]; then
      if [[ ! "$COMMAND" =~ --context.*kind ]]; then
        block_operation "kubectl apply/delete in production requires explicit approval"
      fi
    fi

    # Recursive force delete
    if [[ "$COMMAND" =~ rm[[:space:]]+-rf ]]; then
      if [[ "$COMMAND" =~ /$ ]] || [[ "$COMMAND" =~ \*\* ]]; then
        block_operation "Recursive force delete with dangerous patterns requires approval"
      fi
    fi
    ;;
esac

# Default: allow operation
allow_operation
EOFHOOK

chmod +x hooks/pre_safety_check.sh
```

#### 3. Update settings.json with hook
```bash
cat > settings.json << 'EOF'
{
  "comment": "Settings for Iteration 3 - With safety hook",

  "hooks": {
    "PreToolUse": [
      {
        "comment": "Block dangerous infrastructure operations",
        "matcher": "Bash(terraform apply:*)|Bash(kubectl apply:*)|Bash(kubectl delete:*)|Bash(rm -rf:*)",
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
    "allow": [
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(make:*)",
      "Bash(npm:*)",
      "Bash(pytest:*)",
      "Bash(terraform init:*)",
      "Bash(terraform plan:*)",
      "Bash(terraform workspace:*)",
      "Read",
      "Grep",
      "Glob"
    ],
    "ask": [
      "Bash(terraform apply:*)",
      "Write",
      "Edit"
    ]
  }
}
EOF
```

### Installation

```bash
# Copy hook
mkdir -p ~/.claude/hooks
cp hooks/pre_safety_check.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/pre_safety_check.sh

# Update settings
cp settings.json ~/.claude/

# Verify hook is executable
ls -la ~/.claude/hooks/
# Should show: pre_safety_check.sh with execute permissions (rwxr-xr-x)
```

### Testing

#### Test 1: Hook script works standalone
```bash
# Test blocking terraform apply
echo '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | \
  ~/.claude/hooks/pre_safety_check.sh | jq

# Expected output:
# {
#   "continue": false,
#   "stopReason": "terraform apply requires explicit approval via /pe-apply command",
#   "systemMessage": "⚠️  BLOCKED: terraform apply requires..."
# }
```

#### Test 2: Hook allows safe operations
```bash
# Test allowing terraform plan
echo '{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}' | \
  ~/.claude/hooks/pre_safety_check.sh | jq

# Expected output:
# {
#   "continue": true
# }
```

#### Test 3: Hook integrated in Claude Code
```bash
claude

# In chat, try to trigger blocked operation:
Can you run terraform apply in the current directory?
```

**Expected**:
- Claude is blocked from running the command
- You see message: "⚠️  BLOCKED: terraform apply requires explicit approval..."
- Claude explains it needs approval

#### Test 4: Test other blocked operations
```
Can you run kubectl delete pod my-pod?
```

**Expected**: Operation blocked with appropriate message

#### Test 5: Test allowed operations still work
```
Can you run git status?
```

**Expected**: Command executes normally (no blocking)

### Troubleshooting

**Problem**: Hook doesn't block anything
- Verify hook is executable: `ls -la ~/.claude/hooks/pre_safety_check.sh`
- Test hook manually with echo command (Test 1 above)
- Check settings.json has correct hook path
- Verify matcher patterns: `Bash(terraform apply:*)`
- Restart Claude Code

**Problem**: Hook blocks everything
- Check for syntax errors in hook script
- Verify default case calls `allow_operation`
- Test with simple safe command manually

**Problem**: "jq not found" errors
- Install jq: `brew install jq` (macOS) or `apt-get install jq` (Linux)
- Hook should fallback gracefully if jq missing

**Problem**: Hook timeout errors
- Increase timeout in settings.json (default 30000ms = 30s)
- Check hook script completes quickly
- Add debug output: `echo "Debug: $TOOL_NAME" >&2` before processing

### QA Checkpoint

**Before proceeding to Iteration 4, verify**:
- [ ] Hook script is executable
- [ ] Hook blocks `terraform apply` (test standalone)
- [ ] Hook blocks `kubectl delete` (test standalone)
- [ ] Hook allows `terraform plan` (test standalone)
- [ ] Hook integrated with Claude Code (blocks operations in chat)
- [ ] Safe operations still work normally
- [ ] Blocked operations show helpful error messages

---

## Iteration 4: Telemetry Hook

**Goal**: Add post-operation telemetry logging.

**Duration**: 1 hour

**What Gets Built**:
- `post_telemetry.sh` - Logs tool usage
- Updated `settings.json` with PostToolUse hook
- Telemetry log file

### Files to Create

#### 1. Create post_telemetry.sh
```bash
cat > hooks/post_telemetry.sh << 'EOFHOOK'
#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook for operation telemetry
# Logs tool usage for analysis and audit

INPUT=$(cat)

# Check if telemetry is enabled
if [[ -z "${CLAUDE_TELEMETRY:-}" ]]; then
  # Telemetry disabled, just continue
  echo '{"continue": true, "suppressOutput": true}' >&1
  exit 0
fi

# Extract information (with fallbacks if jq unavailable)
if command -v jq &> /dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
  CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
else
  TOOL_NAME="unknown"
  SESSION_ID="unknown"
  CWD="unknown"
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Determine telemetry file location
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  TELEMETRY_FILE="${CLAUDE_PROJECT_DIR}/.claude/telemetry.jsonl"
else
  TELEMETRY_FILE="${HOME}/.claude/telemetry.jsonl"
fi

# Create directory if needed
mkdir -p "$(dirname "$TELEMETRY_FILE")" 2>/dev/null || true

# Append telemetry entry
if command -v jq &> /dev/null; then
  jq -n \
    --arg ts "$TIMESTAMP" \
    --arg session "$SESSION_ID" \
    --arg tool "$TOOL_NAME" \
    --arg cwd "$CWD" \
    '{timestamp: $ts, session: $session, tool: $tool, cwd: $cwd}' \
    >> "$TELEMETRY_FILE" 2>/dev/null || true
else
  # Fallback without jq
  echo "{\"timestamp\":\"$TIMESTAMP\",\"session\":\"$SESSION_ID\",\"tool\":\"$TOOL_NAME\",\"cwd\":\"$CWD\"}" \
    >> "$TELEMETRY_FILE" 2>/dev/null || true
fi

# Always continue, suppress output
echo '{"continue": true, "suppressOutput": true}' >&1
exit 0
EOFHOOK

chmod +x hooks/post_telemetry.sh
```

#### 2. Update settings.json
```bash
cat > settings.json << 'EOF'
{
  "comment": "Settings for Iteration 4 - With telemetry hook",

  "hooks": {
    "PreToolUse": [
      {
        "comment": "Block dangerous infrastructure operations",
        "matcher": "Bash(terraform apply:*)|Bash(kubectl apply:*)|Bash(kubectl delete:*)|Bash(rm -rf:*)",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",
            "timeout": 30000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "comment": "Log all tool usage for audit and analysis",
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/post_telemetry.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  },

  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(make:*)",
      "Bash(npm:*)",
      "Bash(pytest:*)",
      "Bash(terraform init:*)",
      "Bash(terraform plan:*)",
      "Bash(terraform workspace:*)",
      "Read",
      "Grep",
      "Glob"
    ],
    "ask": [
      "Bash(terraform apply:*)",
      "Write",
      "Edit"
    ]
  },

  "env": {
    "CLAUDE_TELEMETRY": "1"
  }
}
EOF
```

### Installation

```bash
# Copy telemetry hook
cp hooks/post_telemetry.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/post_telemetry.sh

# Update settings
cp settings.json ~/.claude/

# Verify both hooks exist
ls -la ~/.claude/hooks/
# Should show: pre_safety_check.sh, post_telemetry.sh (both executable)
```

### Testing

#### Test 1: Hook works standalone
```bash
# Test with telemetry enabled
export CLAUDE_TELEMETRY=1
echo '{"tool_name":"Bash","tool_input":{"command":"git status"},"session_id":"test-123"}' | \
  ~/.claude/hooks/post_telemetry.sh | jq

# Expected output:
# {
#   "continue": true,
#   "suppressOutput": true
# }
```

#### Test 2: Check telemetry file created
```bash
# Telemetry file should exist
cat ~/.claude/telemetry.jsonl

# Expected: JSON lines with timestamp, session, tool, cwd
# Example:
# {"timestamp":"2025-10-20T12:34:56Z","session":"test-123","tool":"Bash","cwd":"unknown"}
```

#### Test 3: Hook with telemetry disabled
```bash
# Test without CLAUDE_TELEMETRY
unset CLAUDE_TELEMETRY
echo '{"tool_name":"Bash","tool_input":{"command":"git status"}}' | \
  ~/.claude/hooks/post_telemetry.sh | jq

# Expected: Same output, but no new telemetry entry added
```

#### Test 4: Test in Claude Code
```bash
# Clear telemetry file
rm ~/.claude/telemetry.jsonl

claude

# In chat, run a few commands:
Can you check if there's a package.json file?
```

**Expected**:
- Commands execute normally
- No visible output from telemetry hook (suppressOutput: true)
- Telemetry file gets entries

#### Test 5: Verify telemetry logging
```bash
# Check telemetry after a few operations
cat ~/.claude/telemetry.jsonl | jq .

# Expected: Multiple entries showing:
# - Different tools (Read, Bash, Grep, etc.)
# - Timestamps
# - Session IDs
```

### Troubleshooting

**Problem**: Telemetry file not created
- Check CLAUDE_TELEMETRY env var: `echo $CLAUDE_TELEMETRY`
- Verify env set in settings.json
- Check directory permissions: `ls -la ~/.claude/`
- Create directory manually: `mkdir -p ~/.claude`
- Hook fails gracefully, so check for permission issues

**Problem**: Hook slows down operations
- Reduce timeout in settings.json (default 5000ms)
- Check file I/O performance
- Consider async logging (future enhancement)

**Problem**: Invalid JSON in telemetry file
- Check jq is installed and working
- Verify date command works: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Check for partial writes (corruption)

**Problem**: Telemetry file grows too large
- This is expected with many operations
- Add log rotation (future enhancement)
- For now, manually truncate: `> ~/.claude/telemetry.jsonl`

### QA Checkpoint

**Before proceeding to Iteration 5, verify**:
- [ ] Telemetry hook is executable
- [ ] Hook works standalone (test with env var)
- [ ] Hook respects CLAUDE_TELEMETRY flag
- [ ] Telemetry file is created at ~/.claude/telemetry.jsonl
- [ ] Entries logged after operations in Claude Code
- [ ] Operations not slowed down noticeably
- [ ] Hook doesn't interfere with normal operation

---

## Iteration 5: Complete Settings + Permissions

**Goal**: Finalize settings.json with comprehensive permissions and create examples.

**Duration**: 1 hour

**What Gets Built**:
- Complete `settings.json` with all permission categories
- `settings.json.example` - Template for users
- `settings.local.json.example` - Machine-specific overrides

### Files to Create

#### 1. Create comprehensive settings.json
```bash
cat > settings.json << 'EOF'
{
  "comment": "Complete settings.json for osterman .claude configuration",

  "hooks": {
    "PreToolUse": [
      {
        "comment": "Block dangerous infrastructure operations",
        "matcher": "Bash(terraform apply:*)|Bash(kubectl apply:*)|Bash(kubectl delete:*)",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",
            "timeout": 30000
          }
        ]
      },
      {
        "comment": "Block dangerous file operations",
        "matcher": "Bash(rm -rf:*)|Write(/etc/*)|Write(~/.ssh/*)|Write(~/.aws/*)",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",
            "timeout": 10000
          }
        ]
      },
      {
        "comment": "Block database destructive operations",
        "matcher": "Bash(*DROP TABLE*)|Bash(*DROP DATABASE*)",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",
            "timeout": 10000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "comment": "Log all tool usage for audit and analysis",
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/post_telemetry.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  },

  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(npm:*)",
      "Bash(make:*)",
      "Bash(task:*)",
      "Bash(terraform init:*)",
      "Bash(terraform plan:*)",
      "Bash(terraform workspace:*)",
      "Bash(docker ps:*)",
      "Bash(docker images:*)",
      "Bash(ls:*)",
      "Bash(cd:*)",
      "Bash(pwd:*)",
      "Read",
      "Grep",
      "Glob"
    ],
    "ask": [
      "Bash(terraform apply:*)",
      "Bash(kubectl:*)",
      "Bash(aws:*)",
      "Bash(az:*)",
      "Bash(rm:*)",
      "Bash(docker:*)",
      "Write",
      "Edit",
      "NotebookEdit"
    ],
    "deny": [
      "Bash(rm -rf /:*)",
      "Bash(rm -rf ~:*)",
      "Bash(*DROP DATABASE*)"
    ]
  },

  "env": {
    "CLAUDE_TELEMETRY": "1"
  }
}
EOF
```

#### 2. Create settings.json.example
```bash
cat > settings.json.example << 'EOF'
{
  "comment": "Example settings.json for osterman .claude configuration - Copy to settings.json and customize",

  "hooks": {
    "PreToolUse": [
      {
        "comment": "Block dangerous infrastructure operations",
        "matcher": "Bash(terraform apply:*)|Bash(kubectl apply:*)|Bash(kubectl delete:*)",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",
            "timeout": 30000
          }
        ]
      },
      {
        "comment": "Block dangerous file operations",
        "matcher": "Bash(rm -rf:*)|Write(/etc/*)|Write(~/.ssh/*)|Write(~/.aws/*)",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",
            "timeout": 10000
          }
        ]
      },
      {
        "comment": "Block database destructive operations",
        "matcher": "Bash(*DROP TABLE*)|Bash(*DROP DATABASE*)",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",
            "timeout": 10000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "comment": "Log all tool usage for audit and analysis",
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/post_telemetry.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  },

  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(npm:*)",
      "Bash(make:*)",
      "Bash(task:*)",
      "Bash(terraform init:*)",
      "Bash(terraform plan:*)",
      "Bash(terraform workspace:*)",
      "Bash(docker ps:*)",
      "Bash(docker images:*)",
      "Read",
      "Grep",
      "Glob"
    ],
    "ask": [
      "Bash(terraform apply:*)",
      "Bash(kubectl:*)",
      "Bash(aws:*)",
      "Bash(az:*)",
      "Bash(rm:*)",
      "Write",
      "Edit",
      "NotebookEdit"
    ],
    "deny": [
      "Bash(rm -rf /:*)",
      "Bash(rm -rf ~:*)",
      "Bash(*DROP DATABASE*)"
    ]
  },

  "env": {
    "CLAUDE_TELEMETRY": "1"
  }
}
EOF
```

#### 3. Create settings.local.json.example
```bash
cat > settings.local.json.example << 'EOF'
{
  "comment": "Machine-specific settings - copy to settings.local.json and customize",
  "comment2": "This file overrides/extends settings.json for your local machine",
  "comment3": "Add to .gitignore if it contains machine-specific paths or preferences",

  "permissions": {
    "allow": [
      "Bash(test -d /Users/YOUR_USERNAME/.claude)",
      "Read(/Users/YOUR_USERNAME/specific/path/*)"
    ]
  },

  "env": {
    "CLAUDE_TELEMETRY": "0",
    "CUSTOM_ENV_VAR": "value"
  }
}
EOF
```

### Installation

```bash
# Update main settings
cp settings.json ~/.claude/

# Copy example files
cp settings.json.example ~/.claude/
cp settings.local.json.example ~/.claude/

# Optionally create local settings
cp settings.local.json.example ~/.claude/settings.local.json
# Edit as needed: vim ~/.claude/settings.local.json

# Verify
ls ~/.claude/*.json
# Should show: settings.json, settings.json.example, settings.local.json.example
```

### Testing

#### Test 1: Validate JSON syntax
```bash
# Check all JSON files are valid
jq empty ~/.claude/settings.json
jq empty ~/.claude/settings.json.example
jq empty ~/.claude/settings.local.json.example

# Expected: No output means valid JSON
```

#### Test 2: Test allow list
```bash
claude

# In chat, test allowed operations (should work without asking):
Can you run git status?
Can you run make --version?
Can you list files in this directory?
```

**Expected**: Commands execute immediately without permission prompt

#### Test 3: Test ask list
```
Can you create a new file called test.txt with "hello" in it?
```

**Expected**: Claude asks for permission to use Write tool

#### Test 4: Test deny list
```
Can you run rm -rf / --no-preserve-root?
```

**Expected**:
- Operation blocked by hook
- Shows "BLOCKED" message
- Claude refuses to execute

#### Test 5: Test permission hierarchy
```
Can you run terraform plan?
```
**Expected**: Allowed (in allow list)

```
Can you run terraform apply?
```
**Expected**: Claude asks for permission (in ask list) AND hook blocks it

#### Test 6: Test environment variables
```bash
# In Claude Code, check if telemetry is enabled
# Run a few operations and check:
tail -5 ~/.claude/telemetry.jsonl
```

**Expected**: Telemetry entries present (CLAUDE_TELEMETRY=1 working)

### Troubleshooting

**Problem**: JSON syntax errors
- Use `jq empty <file>` to validate
- Check for trailing commas in JSON
- Verify quotes are properly closed
- Use JSON validator online if needed

**Problem**: Permissions too restrictive
- Add more patterns to allow list
- Use wildcards: `Bash(command:*)` not just `Bash(command)`
- Remember: `*` matches anything, `**` for recursive

**Problem**: Permissions too permissive
- Move items from allow to ask list
- Add specific patterns to deny list
- Be cautious with wildcards in allow list

**Problem**: Local settings not applied
- Check file is named `settings.local.json` (not .example)
- Verify JSON syntax
- Settings.local.json extends settings.json (doesn't replace)
- Restart Claude Code

**Problem**: Environment variables not set
- Check `env` section in settings.json
- Verify with: echo $CLAUDE_TELEMETRY in hook script
- Environment vars set per-session by Claude Code

### QA Checkpoint

**Before proceeding to Iteration 6, verify**:
- [ ] All JSON files are valid (jq validates them)
- [ ] Allowed operations work without prompts
- [ ] Ask operations prompt for permission
- [ ] Denied operations are blocked
- [ ] Example files exist and are documented
- [ ] Environment variables working (telemetry active)
- [ ] Permission hierarchy makes sense (allow < ask < deny)

---

## Iteration 6: Remaining Slash Commands

**Goal**: Add the remaining 4 slash commands to complete the command set.

**Duration**: 2 hours

**What Gets Built**:
- `/pe-apply` - Terraform apply with approval
- `/tl-triage` - Issue triage
- `/swe-impl` - Feature implementation
- `/arch-plan` - Architecture planning

### Files to Create

#### 1. Create pe-apply.md
```bash
cat > commands/pe-apply.md << 'EOF'
---
description: Terraform apply with confirm-first approval workflow
argument-hint: DIR=<path> [WORKSPACE=<name>]
allowed-tools: Bash(terraform:*), Bash(make:*), Read, AskUserQuestion
model: sonnet
---

# Production Engineering: Terraform Apply (Confirm-First)

You are operating as the Production Engineering (pe) agent in confirm-first mode for HIGH-RISK operations.

## Task
Run Terraform apply ONLY after explicit user approval.

## Arguments
User provided: $ARGUMENTS
Expected format: `DIR=./infra WORKSPACE=staging`

## Confirm-First Workflow

### Step 1: Run Plan
Execute the plan exactly as in `/pe-plan`:
1. Parse arguments (DIR and WORKSPACE)
2. Run `terraform plan`
3. Analyze and summarize risks

### Step 2: Request Approval
After showing the plan summary, you MUST:
1. Present the risk summary clearly
2. Highlight any Critical or High risk items
3. Ask user for EXPLICIT approval using AskUserQuestion tool:
   - Question: "Do you approve applying this Terraform plan?"
   - Options: "Yes, apply now" OR "No, cancel"
4. **DO NOT PROCEED** without "Yes, apply now" response

### Step 3: Execute Apply (Only If Approved)
If and only if user approves:
1. Run `terraform apply -auto-approve`
2. Monitor output for errors
3. Report success or failure

### Step 4: Post-Apply Actions
After successful apply: Summarize what was applied
After failed apply: Provide diagnostic guidance

## Safety Guardrails

**CRITICAL RULES**:
- NEVER run terraform apply without explicit user approval
- NEVER skip the plan summary step
- ALWAYS show the plan before requesting approval
- ALWAYS use AskUserQuestion for approval

**High-Risk Indicators**:
- Any resource destroys
- IAM permission changes
- Network topology changes
- Production workspace
- Cost impact > $100/month

## Reference Documentation
- **Skills**: `skills/tf_plan_only.md`, `skills/infra_change_review.md`
- **Agent**: `agents/pe.md`
EOF
```

#### 2. Create tl-triage.md
```bash
cat > commands/tl-triage.md << 'EOF'
---
description: Triage open issues with priority recommendations
argument-hint: REPO=<org/name>
allowed-tools: Bash(gh:*), Read, Grep
---

# Team Lead: Issue Triage

Triage open issues for the specified repository.

## Arguments
User provided: $ARGUMENTS
Expected: `REPO=org/name`

## Instructions
1. Fetch open issues:
   ```bash
   gh issue list --repo <org/name> --limit 50 --json number,title,labels,author,createdAt,updatedAt,body
   ```

2. Analyze each issue for:
   - **Priority** (P0/P1/P2/P3 based on urgency, impact)
     - P0: Critical, immediate action (security, data loss, total outage)
     - P1: High, urgent (major features broken, poor UX)
     - P2: Medium, important (minor bugs, improvements)
     - P3: Low, nice-to-have (enhancements, tech debt)
   - **Category** (bug, feature, docs, chore, etc.)
   - **Dependencies** (references to other issues/PRs)
   - **Suggested owner** (based on file paths, labels)

3. Generate dependency graph showing issue relationships

4. Recommend top 10 issues to address first

5. Output format:
   - Summary statistics
   - Priority breakdown
   - Dependency graph
   - Recommended action items
   - Stale issues needing attention

See `skills/gh_issue_triage.md` and `skills/gh_dependency_detect.md` for details.
EOF
```

#### 3. Create swe-impl.md
```bash
cat > commands/swe-impl.md << 'EOF'
---
description: Implement feature following standard branch workflow
argument-hint: TASK="<description>" [SPEC=<url-or-notes>]
allowed-tools: Bash(git:*), Bash(gh:*), Read, Write, Edit, Grep, Glob
---

# Software Engineer: Feature Implementation

Implement a feature following the standard branch workflow.

## Arguments
User provided: $ARGUMENTS
Expected: `TASK="add user auth" SPEC=https://docs.example.com/auth`

## Instructions

Follow the Agent Development Flow from CLAUDE.md:

1. **Preparation**
   - Check out main
   - Pull latest changes
   - Run compile tasks
   - Run all unit tests
   - Run smoke tests (verify main is working)

2. **Create Feature Branch**
   - Create branch: `git checkout -b feature/task-name`

3. **Implementation**
   - Make changes per specification
   - Write/update tests
   - Run tests to verify

4. **Commit and Push**
   - Commit changes with clear message
   - Push branch to remote

5. **Create Pull Request**
   - Create DRAFT PR with `/swe-impl` tag
   - Include:
     - Purpose and summary
     - Test results
     - Screenshots (if UI changes)
   - Request review when ready

6. **Monitoring**
   - Use `gh` to monitor PR workflows
   - Verify checks are green
   - Address any failures

## Safety Guidelines
- Never commit secrets
- Run tests before committing
- Keep commits focused and small
- Write clear commit messages
- Follow project conventions

See `skills/impl_branch_workflow.md` and `CLAUDE.md` Agent Development Flow.
EOF
```

#### 4. Create arch-plan.md
```bash
cat > commands/arch-plan.md << 'EOF'
---
description: Create phased architecture integration plan
argument-hint: FEATURE="<description>"
allowed-tools: Read, Grep, Glob
---

# Software Architect: Integration Plan

Create a phased integration plan for a new feature.

## Arguments
User provided: $ARGUMENTS
Expected: `FEATURE="realtime notifications"`

## Instructions

1. **Analyze Current Architecture**
   - Review existing codebase structure
   - Identify relevant modules/components
   - Understand current patterns and conventions
   - Map dependencies

2. **Identify Integration Points**
   - Where does this feature touch existing code?
   - What new components are needed?
   - What existing components need modification?
   - What contracts/interfaces are affected?

3. **Create Phased Plan**
   For each phase, define:

   **Phase Structure**:
   - Phase goals and deliverables
   - Independent engineer tracks (parallel work)
   - Clear contracts between components
   - Integration points and dependencies
   - Estimated effort

   **Risk Assessment**:
   - Technical risks
   - Integration risks
   - Performance impact
   - Security considerations
   - Backward compatibility

   **Testing Strategy**:
   - Unit tests
   - Integration tests
   - End-to-end tests
   - Performance tests
   - Migration/upgrade tests

   **Rollout/Rollback Strategy**:
   - Feature flags
   - Gradual rollout plan
   - Rollback procedure
   - Monitoring and alerting
   - Success metrics

4. **Output Format**
   ```markdown
   ## Architecture Integration Plan: <Feature Name>

   ### Current State
   [Analysis of existing architecture]

   ### Target State
   [Desired end state]

   ### Phases

   #### Phase 1: <Name>
   - **Goals**: ...
   - **Engineer Tracks**:
     - Track A: ...
     - Track B: ...
   - **Contracts**: ...
   - **Integration Points**: ...
   - **Risk Level**: Low/Medium/High
   - **Estimated Effort**: X days

   [Repeat for each phase]

   ### Risk Register
   [Key risks and mitigations]

   ### Testing Strategy
   [Comprehensive test plan]

   ### Rollout Plan
   [Gradual deployment strategy]

   ### Success Criteria
   [Measurable outcomes]
   ```

See `skills/arch_integration_plan.md` for detailed template.
EOF
```

### Installation

```bash
# Copy new commands
cp commands/pe-apply.md ~/.claude/commands/
cp commands/tl-triage.md ~/.claude/commands/
cp commands/swe-impl.md ~/.claude/commands/
cp commands/arch-plan.md ~/.claude/commands/

# Verify all 8 commands present
ls ~/.claude/commands/
# Should show: pe-plan.md, pe-apply.md, tl-review.md, tl-triage.md,
#              swe-impl.md, test-health.md, dbg.md, arch-plan.md
```

### Testing

#### Test 1: All commands available
```bash
claude

# In chat:
/help
```

**Expected**: All 8 commands listed with descriptions

#### Test 2: Test /pe-apply
```
/pe-apply DIR=./infra WORKSPACE=dev
```

**Expected**:
- Shows plan first
- Requests explicit approval using AskUserQuestion
- Does NOT run apply without approval

#### Test 3: Test /tl-triage
```
/tl-triage REPO=kubernetes/kubernetes
```

**Expected**:
- Uses `gh issue list` to fetch issues
- Categorizes by priority
- Shows recommendations
- May ask for GH authentication

#### Test 4: Test /swe-impl
```
/swe-impl TASK="add health check endpoint"
```

**Expected**:
- Checks current branch
- Asks to create feature branch
- Follows development workflow
- Asks for approval before commits

#### Test 5: Test /arch-plan
```
/arch-plan FEATURE="user authentication system"
```

**Expected**:
- Analyzes codebase
- Creates phased plan
- Identifies integration points
- Provides risk assessment

#### Test 6: Test argument parsing
Try commands with various argument formats:
```
/pe-apply DIR=./infra
/pe-apply DIR=./infra WORKSPACE=staging
/swe-impl TASK="fix bug" SPEC=https://example.com/spec
```

**Expected**: Arguments parsed correctly in each case

### Troubleshooting

**Problem**: Arguments not recognized
- Check frontmatter has `argument-hint`
- Ensure $ARGUMENTS used in command body
- Arguments are free-form text after command
- Format: `KEY=value KEY2=value` or just descriptive text

**Problem**: /pe-apply runs terraform without approval
- Check AskUserQuestion tool is used
- Verify safety hook is active
- Safety hook should block even if command tries to apply
- Test hook manually (Iteration 3 tests)

**Problem**: Commands too verbose
- This is expected for complex commands
- Users can customize commands in their copy
- Commands are templates, not scripts

**Problem**: /swe-impl asks permission for every file
- Check Write/Edit in permissions.ask list
- This is intentional for safety
- Users can move to allow list if desired
- Or approve once at start of session

### QA Checkpoint

**Before proceeding to Iteration 7, verify**:
- [ ] All 8 commands appear in `/help`
- [ ] Each command recognizes its arguments
- [ ] /pe-apply requires approval (doesn't auto-apply)
- [ ] Commands use appropriate tools
- [ ] Complex commands follow workflow steps
- [ ] Argument formats work as documented
- [ ] Commands provide helpful guidance

---

## Iteration 7: Enhanced Hook Features

**Goal**: Add advanced safety checks and better error handling to hooks.

**Duration**: 1.5 hours

**What Gets Built**:
- Enhanced `pre_safety_check.sh` with more patterns
- Warning system (warn but allow)
- Better error messages
- Hook testing script

### Files to Update

#### 1. Enhance pre_safety_check.sh
```bash
cat > hooks/pre_safety_check.sh << 'EOFHOOK'
#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook to enforce safety guardrails
# Version: Iteration 7 - Enhanced

# Read JSON input from stdin
INPUT=$(cat)

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo '{"continue": true}' >&1
  exit 0
fi

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

# Function to block operation with message
block_operation() {
  local reason="$1"
  cat <<EOFJSON >&1
{
  "continue": false,
  "stopReason": "${reason}",
  "systemMessage": "⚠️  BLOCKED: ${reason}"
}
EOFJSON
  exit 0
}

# Function to allow operation
allow_operation() {
  echo '{"continue": true}' >&1
  exit 0
}

# Function to warn but allow
warn_operation() {
  local message="$1"
  cat <<EOFJSON >&1
{
  "continue": true,
  "systemMessage": "⚠️  WARNING: ${message}"
}
EOFJSON
  exit 0
}

# Safety checks based on tool type
case "$TOOL_NAME" in
  "Bash")
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

    # Terraform apply - always block
    if [[ "$COMMAND" =~ terraform[[:space:]]+apply ]]; then
      block_operation "terraform apply requires explicit approval via /pe-apply command"
    fi

    # Kubectl apply/delete in non-kind contexts
    if [[ "$COMMAND" =~ kubectl[[:space:]]+(apply|delete) ]]; then
      if [[ ! "$COMMAND" =~ --context.*kind ]]; then
        block_operation "kubectl apply/delete in production requires explicit approval"
      fi
    fi

    # Recursive force delete - block dangerous patterns
    if [[ "$COMMAND" =~ rm[[:space:]]+-rf ]] || [[ "$COMMAND" =~ rm[[:space:]].*-r.*-f ]]; then
      # Block if deleting root or home
      if [[ "$COMMAND" =~ rm.*(/|~)[[:space:]]*$ ]] || [[ "$COMMAND" =~ rm.*(/|~/)[[:space:]]*$ ]]; then
        block_operation "Cannot delete root or home directory"
      fi
      # Block if recursive pattern like **
      if [[ "$COMMAND" =~ \*\* ]] || [[ "$COMMAND" =~ /\*[[:space:]]*$ ]]; then
        block_operation "Recursive force delete with dangerous patterns requires approval"
      fi
      # Warn for other rm -rf
      warn_operation "Using rm -rf - ensure you intend to delete these files"
    fi

    # Database DROP operations
    if [[ "$COMMAND" =~ (DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)) ]]; then
      block_operation "Database DROP operations require explicit approval"
    fi

    # AWS IAM/Secrets/KMS operations
    if [[ "$COMMAND" =~ aws[[:space:]]+(iam|secretsmanager|kms|sts) ]]; then
      if [[ "$COMMAND" =~ (create|delete|update|put)-[a-z]+ ]]; then
        block_operation "AWS IAM/Secrets/KMS modification operations require approval"
      fi
    fi

    # Git force push to protected branches
    if [[ "$COMMAND" =~ git[[:space:]]+push.*--force ]]; then
      if [[ "$COMMAND" =~ (main|master|production) ]]; then
        block_operation "Force push to protected branches requires approval"
      fi
      warn_operation "Force pushing - ensure this is intentional"
    fi

    # Docker system prune
    if [[ "$COMMAND" =~ docker[[:space:]]+system[[:space:]]+prune ]]; then
      warn_operation "Docker system prune will remove unused containers/images"
    fi

    # npm/yarn publish
    if [[ "$COMMAND" =~ (npm|yarn)[[:space:]]+publish ]]; then
      block_operation "Package publishing requires explicit approval"
    fi
    ;;

  "Write"|"Edit")
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

    # Block writing to system or credential files
    if [[ "$FILE_PATH" =~ ^/etc/ ]] || [[ "$FILE_PATH" =~ /.ssh/ ]] || [[ "$FILE_PATH" =~ /.aws/credentials ]]; then
      block_operation "Writing to system or credential files requires approval"
    fi

    # Warn about .env files (potential secrets)
    if [[ "$FILE_PATH" =~ \.env$ ]] || [[ "$FILE_PATH" =~ \.env\. ]]; then
      warn_operation "Writing to .env file - ensure no secrets are committed"
    fi

    # Warn about config files
    if [[ "$FILE_PATH" =~ (config\.json|secrets\.yaml|credentials\.json)$ ]]; then
      warn_operation "Writing to configuration file - ensure no secrets are included"
    fi
    ;;
esac

# Default: allow operation
allow_operation
EOFHOOK

chmod +x hooks/pre_safety_check.sh
```

#### 2. Create hook test script
```bash
cat > test_hooks.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Testing Hook Functions..."
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test helper function
test_hook() {
  local description="$1"
  local input="$2"
  local expected_result="$3"  # "block", "allow", or "warn"

  echo -n "Test: $description ... "

  OUTPUT=$(echo "$input" | hooks/pre_safety_check.sh 2>&1)

  case "$expected_result" in
    "block")
      if echo "$OUTPUT" | grep -q '"continue": *false'; then
        echo -e "${GREEN}PASS${NC} (correctly blocked)"
        ((PASSED++))
      else
        echo -e "${RED}FAIL${NC} (should block but didn't)"
        echo "  Output: $OUTPUT"
        ((FAILED++))
      fi
      ;;
    "allow")
      if echo "$OUTPUT" | grep -q '"continue": *true' && ! echo "$OUTPUT" | grep -q "WARNING"; then
        echo -e "${GREEN}PASS${NC} (correctly allowed)"
        ((PASSED++))
      else
        echo -e "${RED}FAIL${NC} (should allow but didn't)"
        echo "  Output: $OUTPUT"
        ((FAILED++))
      fi
      ;;
    "warn")
      if echo "$OUTPUT" | grep -q '"continue": *true' && echo "$OUTPUT" | grep -q "WARNING"; then
        echo -e "${GREEN}PASS${NC} (correctly warned)"
        ((PASSED++))
      else
        echo -e "${RED}FAIL${NC} (should warn but didn't)"
        echo "  Output: $OUTPUT"
        ((FAILED++))
      fi
      ;;
  esac
}

echo "=== Safety Hook Tests ==="
echo

# Terraform tests
test_hook "Block terraform apply" \
  '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' \
  "block"

test_hook "Allow terraform plan" \
  '{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}' \
  "allow"

test_hook "Allow terraform init" \
  '{"tool_name":"Bash","tool_input":{"command":"terraform init"}}' \
  "allow"

# Kubectl tests
test_hook "Block kubectl delete (non-kind)" \
  '{"tool_name":"Bash","tool_input":{"command":"kubectl delete pod my-pod"}}' \
  "block"

test_hook "Allow kubectl get" \
  '{"tool_name":"Bash","tool_input":{"command":"kubectl get pods"}}' \
  "allow"

# File operation tests
test_hook "Block rm -rf /" \
  '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
  "block"

test_hook "Warn on rm -rf temp" \
  '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/temp-dir"}}' \
  "warn"

test_hook "Allow rm single file" \
  '{"tool_name":"Bash","tool_input":{"command":"rm file.txt"}}' \
  "allow"

# Database tests
test_hook "Block DROP DATABASE" \
  '{"tool_name":"Bash","tool_input":{"command":"mysql -e \"DROP DATABASE mydb\""}}' \
  "block"

test_hook "Block DROP TABLE" \
  '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP TABLE users\""}}' \
  "block"

# Git tests
test_hook "Block force push to main" \
  '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
  "block"

test_hook "Warn on force push to feature" \
  '{"tool_name":"Bash","tool_input":{"command":"git push --force origin feature/test"}}' \
  "warn"

test_hook "Allow normal git push" \
  '{"tool_name":"Bash","tool_input":{"command":"git push origin feature/test"}}' \
  "allow"

# Write operation tests
test_hook "Block write to /etc/" \
  '{"tool_name":"Write","tool_input":{"file_path":"/etc/hosts"}}' \
  "block"

test_hook "Block write to .ssh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/home/user/.ssh/authorized_keys"}}' \
  "block"

test_hook "Warn on write to .env" \
  '{"tool_name":"Write","tool_input":{"file_path":"/project/.env"}}' \
  "warn"

test_hook "Allow write to normal file" \
  '{"tool_name":"Write","tool_input":{"file_path":"/project/src/file.js"}}' \
  "allow"

# AWS tests
test_hook "Block IAM policy update" \
  '{"tool_name":"Bash","tool_input":{"command":"aws iam put-user-policy"}}' \
  "block"

test_hook "Allow IAM list" \
  '{"tool_name":"Bash","tool_input":{"command":"aws iam list-users"}}' \
  "allow"

# Docker tests
test_hook "Warn on docker system prune" \
  '{"tool_name":"Bash","tool_input":{"command":"docker system prune -af"}}' \
  "warn"

test_hook "Allow docker ps" \
  '{"tool_name":"Bash","tool_input":{"command":"docker ps"}}' \
  "allow"

# Package publishing tests
test_hook "Block npm publish" \
  '{"tool_name":"Bash","tool_input":{"command":"npm publish"}}' \
  "block"

test_hook "Allow npm install" \
  '{"tool_name":"Bash","tool_input":{"command":"npm install"}}' \
  "allow"

echo
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
EOF

chmod +x test_hooks.sh
```

### Installation

```bash
# Update safety hook
cp hooks/pre_safety_check.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/pre_safety_check.sh

# Copy test script (optional, for development)
cp test_hooks.sh ~/.claude/
chmod +x ~/.claude/test_hooks.sh
```

### Testing

#### Test 1: Run hook test suite
```bash
./test_hooks.sh
```

**Expected**: All tests pass

#### Test 2: Test new warning system
```bash
# Test warning (should allow with message)
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/test"}}' | \
  ~/.claude/hooks/pre_safety_check.sh | jq

# Expected:
# {
#   "continue": true,
#   "systemMessage": "⚠️  WARNING: Using rm -rf - ensure you intend to delete these files"
# }
```

#### Test 3: Test new blocks
```bash
# Test npm publish block
echo '{"tool_name":"Bash","tool_input":{"command":"npm publish"}}' | \
  ~/.claude/hooks/pre_safety_check.sh | jq

# Expected: {"continue": false, ...}
```

#### Test 4: Test in Claude Code
```bash
claude

# Try operations that should warn:
Can you remove the /tmp/old-build directory?

# Try operations that should block:
Can you publish this package to npm?
```

**Expected**:
- rm -rf shows warning but proceeds
- npm publish is blocked

#### Test 5: Test .env file warnings
```
Can you create a .env file with database credentials?
```

**Expected**: Warning about .env files and secrets

### Troubleshooting

**Problem**: Tests fail
- Check hook syntax: `bash -n hooks/pre_safety_check.sh`
- Verify jq installed: `which jq`
- Run individual test manually to debug
- Check regex patterns are correct

**Problem**: Warnings not showing in Claude Code
- Warnings show in systemMessage field
- Check Claude Code version supports this
- May show as subtle UI notification
- Check logs if not visible

**Problem**: Hook too aggressive (blocks too much)
- Adjust patterns in hook script
- Move some blocks to warnings
- Customize for your use case
- Users can edit their copy

**Problem**: Hook not aggressive enough
- Add more patterns to block list
- Tighten regex matches
- Add more file path checks
- Consider your specific risks

### QA Checkpoint

**Before proceeding to Iteration 8, verify**:
- [ ] All hook tests pass
- [ ] New blocking patterns work (npm publish, etc.)
- [ ] Warning system works (shows warning, allows operation)
- [ ] Existing blocks still work (terraform apply, etc.)
- [ ] File path protections work (.env, /etc, .ssh)
- [ ] AWS operations properly restricted
- [ ] Git force push protections work
- [ ] Hook provides clear error messages

---

## Iteration 8: Documentation

**Goal**: Create comprehensive documentation for all components.

**Duration**: 2 hours

**What Gets Built**:
- README files for each subdirectory
- Updated main README
- Troubleshooting guide
- Installation instructions

### Files to Create

#### 1. Create commands/README.md
```bash
cat > commands/README.md << 'EOF'
# Slash Commands

Slash commands provide quick access to specialized workflows and agent behaviors in Claude Code.

## What Are Slash Commands?

Slash commands are markdown files with YAML frontmatter that define:
- Command description (shows in `/help`)
- Argument hints (usage guide)
- Allowed tools (permissions)
- Detailed instructions for Claude

## Available Commands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `/test-health` | Analyze test suite health | None |
| `/pe-plan` | Terraform plan analysis | `DIR=<path> [WORKSPACE=<name>]` |
| `/pe-apply` | Terraform apply with approval | `DIR=<path> [WORKSPACE=<name>]` |
| `/tl-review` | Pull request review | `REPO=<org/name> PR=<number>` |
| `/tl-triage` | Issue triage and prioritization | `REPO=<org/name>` |
| `/swe-impl` | Feature implementation workflow | `TASK="<description>" [SPEC=<url>]` |
| `/dbg` | Debug runtime errors | `<description of issue>` |
| `/arch-plan` | Architecture integration plan | `FEATURE="<description>"` |

## Usage Examples

### Infrastructure
```
/pe-plan DIR=./terraform WORKSPACE=staging
/pe-apply DIR=./terraform WORKSPACE=staging
```

### Code Review
```
/tl-review REPO=myorg/myrepo PR=123
/tl-triage REPO=myorg/myrepo
```

### Development
```
/swe-impl TASK="add user authentication"
/dbg TypeError in login function
/test-health
```

### Architecture
```
/arch-plan FEATURE="real-time notifications"
```

## Command Structure

```markdown
---
description: Brief description for /help
argument-hint: Usage hint shown to user
allowed-tools: Tool1, Tool2, Tool3
model: sonnet  # Optional
---

# Command Title

Command instructions for Claude...

## Arguments
User provided: $ARGUMENTS

## Instructions
Step-by-step workflow...
```

## Creating Custom Commands

1. Create `commands/my-command.md`
2. Add YAML frontmatter
3. Write clear instructions
4. Test with `/my-command`

## Tips

- Use descriptive command names
- Provide argument hints
- Reference skills for complex workflows
- Test commands with various inputs
- Keep instructions focused
EOF
```

#### 2. Create hooks/README.md
```bash
cat > hooks/README.md << 'EOF'
# Hooks

Hooks provide automated safety checks and telemetry for Claude Code operations.

## What Are Hooks?

Hooks are executable scripts that intercept tool usage:
- **PreToolUse**: Runs before tool execution (can block)
- **PostToolUse**: Runs after tool execution (logging/telemetry)

## Available Hooks

### Safety Hooks (PreToolUse)

#### pre_safety_check.sh
Blocks dangerous operations:
- `terraform apply` (requires `/pe-apply`)
- `kubectl apply/delete` (non-kind contexts)
- `rm -rf /` or `rm -rf ~` (root/home deletion)
- Database DROP operations
- AWS IAM/secrets/KMS modifications
- Git force push to main/master
- npm/yarn publish
- Writing to system files (/etc, .ssh, .aws)

**Warnings** (allows but warns):
- `rm -rf` other directories
- Git force push to feature branches
- `docker system prune`
- Writing to .env files

### Telemetry Hooks (PostToolUse)

#### post_telemetry.sh
Logs tool usage:
- Tool name
- Timestamp
- Session ID
- Working directory

Logs to: `~/.claude/telemetry.jsonl` or `.claude/telemetry.jsonl`

## Hook Configuration

In `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(terraform apply:*)",
        "hooks": [{
          "type": "command",
          "command": "hooks/pre_safety_check.sh",
          "timeout": 30000
        }]
      }
    ]
  }
}
```

## Testing Hooks

```bash
# Test safety hook
echo '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | \
  hooks/pre_safety_check.sh | jq

# Expected: {"continue": false, "stopReason": "..."}

# Run full test suite
./test_hooks.sh
```

## Creating Custom Hooks

1. Create executable script in `hooks/`
2. Read JSON from stdin
3. Output JSON to stdout:
   - Block: `{"continue": false, "stopReason": "...", "systemMessage": "..."}`
   - Allow: `{"continue": true}`
   - Warn: `{"continue": true, "systemMessage": "⚠️  WARNING: ..."}`
4. Add to settings.json
5. Test standalone and integrated

## Tips

- Always exit 0 (success)
- Use fallbacks if dependencies missing (jq)
- Keep hooks fast (<1s execution)
- Provide clear error messages
- Test edge cases
EOF
```

#### 3. Update main README.md
```bash
cat > README.md << 'EOF'
# Osterman Claude Code Configuration

A production-ready Claude Code configuration template with safety hooks, specialized agents, and workflow automation.

## Features

- **8 Slash Commands**: Quick access to specialized workflows
- **Safety Hooks**: Automated blocking of dangerous operations
- **Telemetry**: Operation logging for audit and analysis
- **Flexible Permissions**: Granular tool access control
- **Agent Workflows**: Structured approaches for common tasks

## Quick Start

### Prerequisites

```bash
# Required
brew install jq
brew install git
brew install gh

# Optional (for specific features)
brew install terraform
```

### Installation

#### Global Installation (Recommended)

```bash
# Backup existing config
if [ -d ~/.claude ]; then
  mv ~/.claude ~/.claude.backup-$(date +%Y%m%d%H%M%S)
fi

# Clone and install
git clone https://github.com/osterman/osterman.git ~/osterman-config
cd ~/osterman-config

mkdir -p ~/.claude
cp -r commands hooks ~/.claude/
cp settings.json.example ~/.claude/settings.json

# Make hooks executable
chmod +x ~/.claude/hooks/*.sh

# Restart Claude Code
```

#### Project-Specific Installation

```bash
# In your project directory
cd /path/to/your/project

# Install to .claude
mkdir -p .claude
cp -r ~/osterman-config/commands .claude/
cp -r ~/osterman-config/hooks .claude/
cp ~/osterman-config/settings.json.example .claude/settings.json

chmod +x .claude/hooks/*.sh
```

### Verification

```bash
claude

# In chat:
/help
# Should show 8 custom commands

# Test a command:
/test-health

# Test safety hook:
# Try: Can you run terraform apply?
# Expected: Operation blocked
```

## Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/test-health` | Test suite analysis | `/test-health` |
| `/pe-plan` | Terraform plan | `/pe-plan DIR=./infra` |
| `/pe-apply` | Terraform apply (with approval) | `/pe-apply DIR=./infra` |
| `/tl-review` | PR review | `/tl-review REPO=org/repo PR=123` |
| `/tl-triage` | Issue triage | `/tl-triage REPO=org/repo` |
| `/swe-impl` | Feature implementation | `/swe-impl TASK="add auth"` |
| `/dbg` | Debug errors | `/dbg TypeError on line 42` |
| `/arch-plan` | Architecture planning | `/arch-plan FEATURE="notifications"` |

## Safety Features

### Blocked Operations
- `terraform apply` (use `/pe-apply` instead)
- `kubectl delete` (production contexts)
- `rm -rf /` or `rm -rf ~`
- Database DROP operations
- AWS IAM/secrets modifications
- Git force push to main/master
- Package publishing (npm/yarn)

### Warnings
- `rm -rf` (other paths)
- Writing to .env files
- Force push to feature branches
- Docker system prune

## Documentation

- [Commands README](commands/README.md) - Slash command details
- [Hooks README](hooks/README.md) - Safety and telemetry hooks
- [Skills README](skills/README.md) - Reusable workflows
- [Agents README](agents/README.md) - Specialized agents

## Customization

### Adding Commands

Create `~/.claude/commands/my-command.md`:

```markdown
---
description: My custom command
argument-hint: <arg1> <arg2>
allowed-tools: Bash, Read, Write
---

# My Command

Instructions for Claude...
```

### Modifying Permissions

Edit `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["Bash(git:*)", "Read"],
    "ask": ["Write", "Edit"],
    "deny": ["Bash(rm -rf /:*)"]
  }
}
```

### Customizing Hooks

Edit hook scripts in `~/.claude/hooks/` to adjust safety rules.

## Troubleshooting

### Commands Not Appearing

```bash
# Check files exist
ls ~/.claude/commands/

# Check file names have .md extension
# Check YAML frontmatter is valid

# Restart Claude Code
```

### Hooks Not Working

```bash
# Check hooks are executable
ls -la ~/.claude/hooks/

# Test hook manually
echo '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | \
  ~/.claude/hooks/pre_safety_check.sh | jq

# Verify jq installed
which jq
```

### Permission Errors

```bash
# Check settings.json
cat ~/.claude/settings.json | jq .permissions

# Verify JSON syntax
jq empty ~/.claude/settings.json
```

## Testing

```bash
# Test hooks
./test_hooks.sh

# Test commands (in Claude Code)
/help
/test-health
```

## Contributing

Contributions welcome! Please:
1. Test changes thoroughly
2. Update documentation
3. Follow existing patterns
4. Submit PR with description

## License

MIT License - See LICENSE file

## Support

- Issues: https://github.com/osterman/osterman/issues
- Docs: https://github.com/osterman/osterman/wiki
EOF
```

#### 4. Create TROUBLESHOOTING.md
```bash
cat > TROUBLESHOOTING.md << 'EOF'
# Troubleshooting Guide

Common issues and solutions for osterman Claude Code configuration.

## Installation Issues

### Commands Not Appearing

**Symptom**: Typing `/pe-plan` shows "Unknown command"

**Solutions**:
1. Verify files in correct location:
   ```bash
   ls ~/.claude/commands/
   # Should show: *.md files
   ```

2. Check file names match command names:
   - File: `pe-plan.md` → Command: `/pe-plan`
   - Must have `.md` extension

3. Verify YAML frontmatter is valid:
   ```bash
   head -n 10 ~/.claude/commands/pe-plan.md
   # Should show valid YAML between ---
   ```

4. Restart Claude Code completely

5. Check `/help` to see available commands

### Hooks Not Executing

**Symptom**: Dangerous commands not being blocked

**Solutions**:
1. Verify hooks are executable:
   ```bash
   ls -la ~/.claude/hooks/
   # Should show -rwxr-xr-x permissions
   ```

2. Make executable if needed:
   ```bash
   chmod +x ~/.claude/hooks/*.sh
   ```

3. Test hook standalone:
   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | \
     ~/.claude/hooks/pre_safety_check.sh | jq
   ```

4. Check settings.json has correct paths:
   ```bash
   cat ~/.claude/settings.json | jq .hooks
   ```

5. Verify jq installed:
   ```bash
   which jq || brew install jq
   ```

## Permission Issues

### Constant Permission Prompts

**Symptom**: Claude asks permission for every git/read operation

**Solutions**:
1. Check allow list uses wildcards:
   ```json
   "allow": [
     "Bash(git:*)",  // Correct
     "Bash(git)"     // Wrong - too specific
   ]
   ```

2. Add common tools to allow list:
   ```json
   "allow": [
     "Bash(git:*)",
     "Bash(gh:*)",
     "Bash(make:*)",
     "Read",
     "Grep",
     "Glob"
   ]
   ```

3. Restart Claude Code after settings changes

### Operations Being Blocked

**Symptom**: Safe operations blocked by hooks

**Solutions**:
1. Test hook manually to debug:
   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"YOUR COMMAND"}}' | \
     ~/.claude/hooks/pre_safety_check.sh | jq
   ```

2. Check hook patterns in script:
   ```bash
   grep -n "YOUR_OPERATION" ~/.claude/hooks/pre_safety_check.sh
   ```

3. Customize hook for your needs:
   - Edit `~/.claude/hooks/pre_safety_check.sh`
   - Adjust regex patterns
   - Change blocks to warnings

4. Temporarily disable hook to test:
   - Comment out hook in settings.json
   - Restart Claude Code
   - Remember to re-enable!

## Hook Issues

### Hook Timeout Errors

**Symptom**: "Hook timed out" messages

**Solutions**:
1. Increase timeout in settings.json:
   ```json
   {
     "hooks": [{
       "timeout": 30000  // 30 seconds
     }]
   }
   ```

2. Optimize hook performance:
   - Remove expensive operations
   - Cache results if possible
   - Use faster alternatives

3. Debug slow operations:
   ```bash
   time echo '{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}' | \
     ~/.claude/hooks/pre_safety_check.sh
   ```

### Telemetry Not Logging

**Symptom**: telemetry.jsonl file not created or empty

**Solutions**:
1. Check CLAUDE_TELEMETRY env var:
   ```bash
   # In settings.json
   "env": {
     "CLAUDE_TELEMETRY": "1"
   }
   ```

2. Check directory permissions:
   ```bash
   ls -la ~/.claude/
   mkdir -p ~/.claude
   chmod 755 ~/.claude
   ```

3. Test hook manually:
   ```bash
   export CLAUDE_TELEMETRY=1
   echo '{"tool_name":"Bash","session_id":"test"}' | \
     ~/.claude/hooks/post_telemetry.sh
   cat ~/.claude/telemetry.jsonl
   ```

4. Check for file permission errors:
   ```bash
   touch ~/.claude/telemetry.jsonl
   chmod 644 ~/.claude/telemetry.jsonl
   ```

### Invalid JSON in Telemetry

**Symptom**: Cannot parse telemetry.jsonl

**Solutions**:
1. Validate file:
   ```bash
   cat ~/.claude/telemetry.jsonl | while read line; do echo "$line" | jq empty || echo "Invalid: $line"; done
   ```

2. Check jq availability:
   ```bash
   which jq || brew install jq
   ```

3. Backup and recreate:
   ```bash
   mv ~/.claude/telemetry.jsonl ~/.claude/telemetry.jsonl.backup
   # Telemetry will create new file
   ```

## Command Issues

### Arguments Not Working

**Symptom**: Command doesn't parse arguments like `DIR=./infra`

**Solutions**:
1. Check argument format:
   - Correct: `/pe-plan DIR=./infra WORKSPACE=staging`
   - Correct: `/swe-impl TASK="add feature"`
   - Wrong: `/pe-plan --dir=./infra`

2. Verify command has $ARGUMENTS in body:
   ```bash
   grep '\$ARGUMENTS' ~/.claude/commands/pe-plan.md
   ```

3. Check argument-hint in frontmatter:
   ```bash
   head -n 5 ~/.claude/commands/pe-plan.md
   ```

### Command Behavior Issues

**Symptom**: Command doesn't follow expected workflow

**Solutions**:
1. Read command file to understand instructions:
   ```bash
   cat ~/.claude/commands/pe-plan.md
   ```

2. Commands are guidelines, not strict scripts
   - Claude interprets instructions
   - May vary based on context
   - Customize command files as needed

3. Update command for your specific needs:
   - Edit `~/.claude/commands/COMMAND.md`
   - Add more specific instructions
   - Reference your project structure

## Settings Issues

### JSON Syntax Errors

**Symptom**: Settings not loading, errors on startup

**Solutions**:
1. Validate JSON:
   ```bash
   jq empty ~/.claude/settings.json
   ```

2. Common errors:
   - Trailing commas (JSON doesn't allow)
   - Missing quotes on keys/values
   - Unclosed brackets/braces

3. Use JSON formatter:
   ```bash
   cat ~/.claude/settings.json | jq . > ~/.claude/settings.json.formatted
   mv ~/.claude/settings.json.formatted ~/.claude/settings.json
   ```

4. Restore from example:
   ```bash
   cp ~/osterman-config/settings.json.example ~/.claude/settings.json
   ```

### Local Settings Not Applied

**Symptom**: settings.local.json changes not taking effect

**Solutions**:
1. Verify file name (no .example suffix):
   ```bash
   ls ~/.claude/settings*.json
   ```

2. Check JSON syntax:
   ```bash
   jq empty ~/.claude/settings.local.json
   ```

3. Restart Claude Code

4. Understand merge behavior:
   - Local settings extend/override global settings
   - Arrays are merged
   - Objects are overridden

## Performance Issues

### Slow Operations

**Symptom**: Claude Code operations slow or laggy

**Solutions**:
1. Check hook timeouts:
   - Reduce timeout for fast hooks
   - Optimize hook scripts

2. Disable telemetry temporarily:
   ```json
   "env": {
     "CLAUDE_TELEMETRY": "0"
   }
   ```

3. Simplify hook patterns:
   - Remove unnecessary regex complexity
   - Cache expensive operations

4. Check system resources:
   ```bash
   top
   # Look for high CPU/memory usage
   ```

### Large Telemetry File

**Symptom**: telemetry.jsonl grows very large

**Solutions**:
1. Archive old logs:
   ```bash
   mv ~/.claude/telemetry.jsonl ~/.claude/telemetry-$(date +%Y%m%d).jsonl
   gzip ~/.claude/telemetry-$(date +%Y%m%d).jsonl
   ```

2. Disable telemetry if not needed:
   ```json
   "env": {
     "CLAUDE_TELEMETRY": "0"
   }
   ```

3. Implement log rotation (future enhancement)

## Testing and Debugging

### Testing Hooks

```bash
# Run full hook test suite
./test_hooks.sh

# Test specific pattern
echo '{"tool_name":"Bash","tool_input":{"command":"YOUR_COMMAND"}}' | \
  ~/.claude/hooks/pre_safety_check.sh | jq

# Test with debug output
bash -x ~/.claude/hooks/pre_safety_check.sh <<< '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}'
```

### Testing Commands

```bash
# In Claude Code:
/help                           # List all commands
/pe-plan --help                 # Command-specific help (if supported)
/pe-plan DIR=./test WORKSPACE=dev  # Test with real args
```

### Debug Mode

Add debug output to hooks:

```bash
# In hook script, add:
echo "DEBUG: TOOL_NAME=$TOOL_NAME" >&2
echo "DEBUG: COMMAND=$COMMAND" >&2
```

Check stderr:
```bash
echo '...' | ~/.claude/hooks/pre_safety_check.sh 2>&1 | grep DEBUG
```

## Getting Help

If issues persist:

1. Check GitHub issues: https://github.com/osterman/osterman/issues
2. Review documentation: Each directory has README.md
3. Test with minimal configuration:
   ```bash
   # Create minimal settings.json with just one command
   # Test incrementally
   ```
4. Share debug info in issue:
   - Claude Code version
   - OS version (Darwin/Linux)
   - Output of test commands
   - Relevant logs/errors

## Common Patterns

### Fresh Install

```bash
# Complete reset
rm -rf ~/.claude
git clone https://github.com/osterman/osterman.git ~/osterman-config
cd ~/osterman-config
mkdir -p ~/.claude
cp -r commands hooks ~/.claude/
cp settings.json.example ~/.claude/settings.json
chmod +x ~/.claude/hooks/*.sh
# Restart Claude Code
```

### Update Configuration

```bash
# Pull latest
cd ~/osterman-config
git pull

# Update files
cp -r commands hooks ~/.claude/
# Keep your customized settings.json
chmod +x ~/.claude/hooks/*.sh
# Restart Claude Code
```

### Test After Changes

```bash
# 1. Test hooks
./test_hooks.sh

# 2. Restart Claude Code

# 3. Test commands
claude
/help
/test-health

# 4. Verify permissions
# Try allowed operation (should work)
# Try ask operation (should prompt)
# Try blocked operation (should block)
```
EOF
```

### Installation

```bash
# Copy all documentation files
cp commands/README.md ~/.claude/commands/
cp hooks/README.md ~/.claude/hooks/
cp README.md ~/.claude/
cp TROUBLESHOOTING.md ~/.claude/

# Verify
ls ~/.claude/*.md
ls ~/.claude/commands/README.md
ls ~/.claude/hooks/README.md
```

### Testing

#### Test 1: Verify all docs exist
```bash
ls ~/.claude/*.md
# Should show: README.md, TROUBLESHOOTING.md

ls ~/.claude/commands/README.md
ls ~/.claude/hooks/README.md
```

#### Test 2: Docs are readable
```bash
# Open in editor or less
less ~/.claude/README.md
less ~/.claude/TROUBLESHOOTING.md
less ~/.claude/commands/README.md
less ~/.claude/hooks/README.md
```

#### Test 3: Docs are accurate
- Read through each document
- Verify commands/examples are correct
- Check links and references work
- Ensure instructions match actual behavior

#### Test 4: Follow installation from README
```bash
# In a test directory
# Follow the installation steps exactly as documented
# Verify everything works
```

### QA Checkpoint

**Before proceeding to Iteration 9, verify**:
- [ ] All README files created
- [ ] Main README has installation instructions
- [ ] TROUBLESHOOTING.md covers common issues
- [ ] Commands documented with examples
- [ ] Hooks documented with configuration
- [ ] Documentation is clear and accurate
- [ ] Examples are correct and tested
- [ ] Links and references work

---

## Iteration 9: Integration Testing

**Goal**: Create comprehensive integration test and validate entire system.

**Duration**: 1.5 hours

**What Gets Built**:
- Integration test script
- Installation validator
- Complete system test

### Files to Create

#### 1. Create integration test script
```bash
cat > test_integration.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Comprehensive integration test for osterman .claude configuration

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Test helper
test_step() {
  local description="$1"
  shift

  echo -en "${BLUE}Testing:${NC} $description ... "

  if "$@" > /tmp/test_output.txt 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    echo "  Output:"
    sed 's/^/    /' /tmp/test_output.txt
    ((FAILED++))
    return 1
  fi
}

warn_step() {
  local message="$1"
  echo -e "${YELLOW}WARNING:${NC} $message"
  ((WARNINGS++))
}

echo -e "${BLUE}=== Osterman .claude Configuration Integration Test ===${NC}"
echo

# Test 1: Check prerequisites
echo -e "${BLUE}=== Prerequisites ===${NC}"

test_step "jq is installed" \
  command -v jq

test_step "git is installed" \
  command -v git

if ! command -v gh &> /dev/null; then
  warn_step "gh CLI not installed (optional, needed for /tl-review, /tl-triage)"
fi

if ! command -v terraform &> /dev/null; then
  warn_step "terraform not installed (optional, needed for /pe-plan, /pe-apply)"
fi

echo

# Test 2: File structure
echo -e "${BLUE}=== File Structure ===${NC}"

test_step "commands directory exists" \
  test -d commands

test_step "hooks directory exists" \
  test -d hooks

test_step "All 8 command files exist" \
  bash -c '[ $(ls commands/*.md 2>/dev/null | wc -l) -eq 8 ]'

test_step "Both hook scripts exist" \
  bash -c '[ $(ls hooks/*.sh 2>/dev/null | wc -l) -eq 2 ]'

test_step "settings.json.example exists" \
  test -f settings.json.example

test_step "README.md exists" \
  test -f README.md

test_step "TROUBLESHOOTING.md exists" \
  test -f TROUBLESHOOTING.md

echo

# Test 3: Hook executability
echo -e "${BLUE}=== Hook Executability ===${NC}"

test_step "pre_safety_check.sh is executable" \
  test -x hooks/pre_safety_check.sh

test_step "post_telemetry.sh is executable" \
  test -x hooks/post_telemetry.sh

echo

# Test 4: JSON validity
echo -e "${BLUE}=== JSON Validity ===${NC}"

test_step "settings.json.example is valid JSON" \
  jq empty settings.json.example

test_step "settings.local.json.example is valid JSON" \
  jq empty settings.local.json.example

echo

# Test 5: Command structure
echo -e "${BLUE}=== Command Structure ===${NC}"

for cmd in commands/*.md; do
  cmd_name=$(basename "$cmd" .md)

  test_step "[$cmd_name] has YAML frontmatter" \
    bash -c "head -n 1 '$cmd' | grep -q '^---$'"

  test_step "[$cmd_name] has description" \
    bash -c "grep -q '^description:' '$cmd'"
done

echo

# Test 6: Hook functionality (unit tests)
echo -e "${BLUE}=== Hook Functionality ===${NC}"

test_step "Hook blocks terraform apply" \
  bash -c '! echo '"'"'{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}'"'"' | hooks/pre_safety_check.sh | jq -e '"'"'.continue == false'"'"' > /dev/null'

test_step "Hook allows terraform plan" \
  bash -c 'echo '"'"'{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}'"'"' | hooks/pre_safety_check.sh | jq -e '"'"'.continue == true'"'"' > /dev/null'

test_step "Hook blocks kubectl delete" \
  bash -c '! echo '"'"'{"tool_name":"Bash","tool_input":{"command":"kubectl delete pod test"}}'"'"' | hooks/pre_safety_check.sh | jq -e '"'"'.continue == false'"'"' > /dev/null'

test_step "Hook blocks rm -rf /" \
  bash -c '! echo '"'"'{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}'"'"' | hooks/pre_safety_check.sh | jq -e '"'"'.continue == false'"'"' > /dev/null'

test_step "Hook allows git commands" \
  bash -c 'echo '"'"'{"tool_name":"Bash","tool_input":{"command":"git status"}}'"'"' | hooks/pre_safety_check.sh | jq -e '"'"'.continue == true'"'"' > /dev/null'

test_step "Telemetry hook succeeds" \
  bash -c 'CLAUDE_TELEMETRY=1 echo '"'"'{"tool_name":"Bash","session_id":"test"}'"'"' | hooks/post_telemetry.sh | jq -e '"'"'.continue == true'"'"' > /dev/null'

echo

# Test 7: Settings structure
echo -e "${BLUE}=== Settings Structure ===${NC}"

test_step "settings.json.example has hooks section" \
  bash -c 'jq -e ".hooks" settings.json.example > /dev/null'

test_step "settings.json.example has PreToolUse hooks" \
  bash -c 'jq -e ".hooks.PreToolUse | length > 0" settings.json.example > /dev/null'

test_step "settings.json.example has PostToolUse hooks" \
  bash -c 'jq -e ".hooks.PostToolUse | length > 0" settings.json.example > /dev/null'

test_step "settings.json.example has permissions" \
  bash -c 'jq -e ".permissions" settings.json.example > /dev/null'

test_step "settings.json.example has allow list" \
  bash -c 'jq -e ".permissions.allow | length > 0" settings.json.example > /dev/null'

test_step "settings.json.example has ask list" \
  bash -c 'jq -e ".permissions.ask | length > 0" settings.json.example > /dev/null'

test_step "settings.json.example has env vars" \
  bash -c 'jq -e ".env" settings.json.example > /dev/null'

echo

# Test 8: Documentation completeness
echo -e "${BLUE}=== Documentation Completeness ===${NC}"

test_step "README.md has installation instructions" \
  bash -c 'grep -q "Installation" README.md'

test_step "README.md has command list" \
  bash -c 'grep -q "Available Commands" README.md'

test_step "commands/README.md exists" \
  test -f commands/README.md

test_step "hooks/README.md exists" \
  test -f hooks/README.md

test_step "TROUBLESHOOTING.md has sections" \
  bash -c 'grep -q "## Installation Issues" TROUBLESHOOTING.md && grep -q "## Permission Issues" TROUBLESHOOTING.md'

echo

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "Passed:   ${GREEN}$PASSED${NC}"
echo -e "Failed:   ${RED}$FAILED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All tests passed! Configuration is ready.${NC}"
  echo
  echo "Next steps:"
  echo "  1. Review documentation in README.md"
  echo "  2. Install to ~/.claude (see README.md)"
  echo "  3. Test in Claude Code with /help"
  echo "  4. Customize settings.json for your needs"
  exit 0
else
  echo -e "${RED}❌ Some tests failed. Please fix issues before using.${NC}"
  echo
  echo "Troubleshooting:"
  echo "  - Review failed tests above"
  echo "  - Check TROUBLESHOOTING.md for solutions"
  echo "  - Verify all files are present and correctly formatted"
  exit 1
fi
EOF

chmod +x test_integration.sh
```

#### 2. Create installation validator
```bash
cat > validate_installation.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Validates installation at ~/.claude or specified path

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_PATH="${1:-$HOME/.claude}"

echo -e "${BLUE}=== Validating Installation at: $INSTALL_PATH ===${NC}"
echo

PASSED=0
FAILED=0

check() {
  local description="$1"
  shift

  echo -en "Checking: $description ... "

  if "$@" > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
    return 1
  fi
}

# Check directory exists
check "Installation directory exists" \
  test -d "$INSTALL_PATH"

# Check subdirectories
check "commands/ directory exists" \
  test -d "$INSTALL_PATH/commands"

check "hooks/ directory exists" \
  test -d "$INSTALL_PATH/hooks"

# Check commands
echo
echo "Checking commands..."
EXPECTED_COMMANDS=(
  "test-health"
  "pe-plan"
  "pe-apply"
  "tl-review"
  "tl-triage"
  "swe-impl"
  "dbg"
  "arch-plan"
)

for cmd in "${EXPECTED_COMMANDS[@]}"; do
  check "  /$cmd command exists" \
    test -f "$INSTALL_PATH/commands/${cmd}.md"
done

# Check hooks
echo
echo "Checking hooks..."
check "pre_safety_check.sh exists" \
  test -f "$INSTALL_PATH/hooks/pre_safety_check.sh"

check "pre_safety_check.sh is executable" \
  test -x "$INSTALL_PATH/hooks/pre_safety_check.sh"

check "post_telemetry.sh exists" \
  test -f "$INSTALL_PATH/hooks/post_telemetry.sh"

check "post_telemetry.sh is executable" \
  test -x "$INSTALL_PATH/hooks/post_telemetry.sh"

# Check settings
echo
echo "Checking settings..."
check "settings.json exists" \
  test -f "$INSTALL_PATH/settings.json"

if [ -f "$INSTALL_PATH/settings.json" ]; then
  check "settings.json is valid JSON" \
    jq empty "$INSTALL_PATH/settings.json"
fi

# Check documentation
echo
echo "Checking documentation..."
check "README.md exists" \
  test -f "$INSTALL_PATH/README.md"

check "commands/README.md exists" \
  test -f "$INSTALL_PATH/commands/README.md"

check "hooks/README.md exists" \
  test -f "$INSTALL_PATH/hooks/README.md"

# Summary
echo
echo -e "${BLUE}=== Validation Summary ===${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ Installation validated successfully!${NC}"
  echo
  echo "Your osterman configuration is ready to use."
  echo
  echo "Quick test:"
  echo "  1. Start Claude Code: claude"
  echo "  2. Type: /help"
  echo "  3. Try a command: /test-health"
  exit 0
else
  echo -e "${RED}❌ Installation validation failed.${NC}"
  echo
  echo "Please fix the issues above."
  echo "See TROUBLESHOOTING.md for help."
  exit 1
fi
EOF

chmod +x validate_installation.sh
```

### Installation

```bash
# Copy test scripts
cp test_integration.sh ~/.claude/
cp validate_installation.sh ~/.claude/
chmod +x ~/.claude/test_integration.sh
chmod +x ~/.claude/validate_installation.sh

# Or keep in project for development
# These are development tools, not part of installed config
```

### Testing

#### Test 1: Run integration test suite
```bash
./test_integration.sh
```

**Expected**: All tests pass, summary shows green

#### Test 2: Test individual failures
```bash
# Temporarily break something
mv commands/test-health.md commands/test-health.md.bak

# Run test
./test_integration.sh
# Should show failure for missing command file

# Fix it
mv commands/test-health.md.bak commands/test-health.md

# Test again
./test_integration.sh
# Should pass
```

#### Test 3: Validate installation
```bash
# Install to test location
mkdir -p /tmp/test-claude
cp -r commands hooks /tmp/test-claude/
cp settings.json.example /tmp/test-claude/settings.json
chmod +x /tmp/test-claude/hooks/*.sh

# Validate
./validate_installation.sh /tmp/test-claude

# Should pass all checks
```

#### Test 4: Full end-to-end test
```bash
# 1. Run integration test
./test_integration.sh

# 2. Install to ~/.claude
# (Back up first if already exists)
if [ -d ~/.claude ]; then
  mv ~/.claude ~/.claude.backup-$(date +%Y%m%d%H%M%S)
fi

mkdir -p ~/.claude
cp -r commands hooks ~/.claude/
cp settings.json.example ~/.claude/settings.json
chmod +x ~/.claude/hooks/*.sh
cp README.md TROUBLESHOOTING.md ~/.claude/
cp commands/README.md ~/.claude/commands/
cp hooks/README.md ~/.claude/hooks/

# 3. Validate installation
./validate_installation.sh

# 4. Test in Claude Code
claude

# In chat:
/help
/test-health
# Try: Can you run terraform apply?
# (Should be blocked)
```

### Troubleshooting

**Problem**: Integration test fails
- Review failed test output
- Check file exists and has correct content
- Verify JSON syntax
- Check hook executability
- Run test with `bash -x test_integration.sh` for debug

**Problem**: Validation fails
- Check all files copied correctly
- Verify permissions
- Ensure hooks are executable
- Check settings.json is valid JSON

**Problem**: Tests pass but Claude Code doesn't work
- Restart Claude Code completely
- Check Claude Code version compatibility
- Verify files in correct location
- Check Claude Code logs for errors

### QA Checkpoint

**Final validation before completion**:
- [ ] Integration test passes all checks
- [ ] Validation script confirms installation
- [ ] All 8 commands work in Claude Code
- [ ] Safety hooks block dangerous operations
- [ ] Telemetry logging works
- [ ] Permissions configured correctly
- [ ] Documentation complete and accurate
- [ ] No JSON syntax errors
- [ ] Hooks executable and functional
- [ ] Ready for production use

---

## Completion Checklist

### All Iterations Complete

- [ ] **Iteration 1**: Single command working
- [ ] **Iteration 2**: Multiple commands working
- [ ] **Iteration 3**: Safety hook blocking operations
- [ ] **Iteration 4**: Telemetry logging
- [ ] **Iteration 5**: Complete settings configuration
- [ ] **Iteration 6**: All 8 commands created
- [ ] **Iteration 7**: Enhanced hook features
- [ ] **Iteration 8**: Documentation complete
- [ ] **Iteration 9**: Integration tests passing

### Final Validation

```bash
# Run all tests
./test_hooks.sh
./test_integration.sh

# Install and validate
./validate_installation.sh

# Manual test in Claude Code
claude
/help
/pe-plan DIR=./test
# Try dangerous operation (should block)
```

### Success Criteria Met

- All slash commands functional
- Safety hooks blocking dangerous operations
- Telemetry logging working
- Permissions properly configured
- Documentation complete
- Installation smooth and validated
- Integration tests passing
- Ready for distribution

## Timeline Summary

| Iteration | Duration | Cumulative |
|-----------|----------|------------|
| 1 | 1 hour | 1 hour |
| 2 | 1.5 hours | 2.5 hours |
| 3 | 1.5 hours | 4 hours |
| 4 | 1 hour | 5 hours |
| 5 | 1 hour | 6 hours |
| 6 | 2 hours | 8 hours |
| 7 | 1.5 hours | 9.5 hours |
| 8 | 2 hours | 11.5 hours |
| 9 | 1.5 hours | 13 hours |

**Total Estimated Time**: 13 hours (split across 2-3 days with QA checkpoints)

## Next Steps After Completion

1. **Commit to Git**
   ```bash
   git add -A
   git commit -m "Complete osterman .claude configuration with iterative build"
   git tag v1.0.0
   git push origin main --tags
   ```

2. **Create Release**
   - Tag release on GitHub
   - Add release notes
   - Include installation instructions

3. **Documentation**
   - Add CHANGELOG.md
   - Update README with version info
   - Add examples directory

4. **Distribution**
   - Share with team
   - Gather feedback
   - Iterate based on usage

5. **Maintenance**
   - Monitor issues
   - Update documentation
   - Add new commands as needed
   - Enhance hooks based on patterns
