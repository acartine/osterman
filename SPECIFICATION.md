# Osterman .claude Configuration - Updated Specification

## Executive Summary

The osterman repository is a template for a user-level `.claude` configuration that demonstrates proper Claude Code configuration with agents, skills, hooks, and slash commands. This document identifies what's currently broken, what the correct formats should be, and provides a comprehensive plan to fix the configuration based on official Claude Code documentation.

## Original Goals (from EXECUTION.md)

1. **Autonomous Agents with Guardrails**: Create subagents that operate autonomously by default with safe guardrails for high-risk operations
2. **Consolidated Production Engineering**: Merge infra + pair-programmer into a hybrid `pe` agent
3. **Token Optimization**: Use lean prompts, shared skills, and hooks to reduce token usage
4. **Reusable Skills**: Factor common patterns into composable skills
5. **Safety Hooks**: Implement cross-cutting guardrails for destructive operations
6. **Slash Command Shortcuts**: Provide convenient shortcuts for common workflows

## Current State Analysis

### Directory Structure (Current)

```
/Users/cartine/osterman/
├── .claude/
│   └── settings.local.json          # Exists but incomplete
├── agents/                           # Exists, properly formatted
│   ├── pe.md
│   ├── tl.md
│   ├── swe.md
│   ├── test-engineer.md
│   ├── code-debugger.md
│   └── software-architect.md
├── hooks/                            # Exists but WRONG FORMAT
│   ├── command_router.md
│   ├── pre_safety.md
│   ├── context_trim.md
│   ├── post_telemetry.md
│   └── gh_event_heuristics.md
├── skills/                           # Exists, proper format (for documentation)
│   ├── gh_pr_review.md
│   ├── tf_plan_only.md
│   └── ... (11 more)
├── bin/                              # Exists, proper shell scripts
│   ├── gh-pr-review
│   └── ... (9 more)
├── CLAUDE.md                         # Proper format
├── COMMANDS.md
├── EXECUTION.md
├── PROMPTING_GUIDE.md
└── README.md
```

### What's Currently Broken

#### 1. **CRITICAL: Missing `.claude/commands/` Directory**

**Problem**: The slash commands are documented in `hooks/command_router.md` as a "hook" but Claude Code expects slash commands to be in `.claude/commands/` as individual Markdown files.

**Current (Wrong)**:
- Location: `hooks/command_router.md`
- Format: Single markdown file with YAML frontmatter listing all commands
- This is treated as a hook, not actual slash commands

**Should Be**:
- Location: `.claude/commands/` directory with individual files
- Format: One `.md` file per command (e.g., `pe-plan.md`, `tl-review.md`)
- Each file contains the prompt and optional frontmatter with metadata

**Impact**: Slash commands like `/pe plan`, `/tl review` etc. are NOT working at all. They don't exist as far as Claude Code is concerned.

#### 2. **Hooks are Documentation-Only, Not Executable**

**Problem**: Current hooks (`pre_safety.md`, `context_trim.md`, etc.) are markdown documentation files with YAML frontmatter, but Claude Code hooks must be **executable scripts** that output JSON.

**Current (Wrong)**:
```markdown
---
name: pre_safety
event: pre
description: Intercept risky or destructive actions...
policy:
  - Block terraform/kubectl apply...
---
```

**Should Be**:
- Executable script (e.g., `hooks/pre_safety.sh` or `hooks/pre_safety.py`)
- Configured in `.claude/settings.json` with proper JSON structure
- Receives input via stdin, outputs JSON to stdout
- Example output format:
```json
{
  "continue": true,
  "stopReason": "Blocked: terraform apply requires approval",
  "suppressOutput": false,
  "systemMessage": "This operation requires explicit approval"
}
```

**Impact**: Hooks are not being invoked at all. Safety guardrails, context trimming, telemetry, and command routing are non-functional.

#### 3. **Agent References Non-Existent Hooks/Skills**

**Problem**: Agents like `pe.md` and `tl.md` reference hooks and skills in their frontmatter:

```yaml
hooks: [ command_router, pre_safety, context_trim, post_telemetry ]
skills: [ tf_plan_only, infra_change_review, ... ]
```

But:
- Hooks don't exist as executable scripts
- Skills are documentation only, not callable functions
- Agents have no way to actually invoke these

**What Claude Code Actually Supports**:
- Agents are selected manually by the user
- Agents can reference documentation for guidance
- Hooks are configured in settings.json and run automatically
- Skills are conceptual patterns documented in markdown files for the agent to follow

**Impact**: The frontmatter is documentation-only metadata. Agents can't programmatically invoke hooks or skills.

#### 4. **Settings Configuration is Incomplete**

**Current** `.claude/settings.local.json`:
```json
{
  "permissions": {
    "allow": ["Bash(test -d /Users/cartine/.claude)"],
    "deny": [],
    "ask": []
  }
}
```

**Missing**:
- Hook configurations
- Model preferences
- Custom tool permissions
- Timeout settings

## Official Claude Code Standards (from Documentation)

### Slash Commands Format

**Location**: `.claude/commands/` directory

**File Structure**: One `.md` file per command

**Example**: `.claude/commands/pe-plan.md`

```markdown
---
description: Run Terraform plan-only and summarize risks
argument-hint: [DIR] [WORKSPACE]
allowed-tools: Bash(terraform:*), Bash(make:*)
model: claude-3-5-sonnet-20241022
---

You are the Production Engineering (pe) agent.

Run a Terraform plan-only operation for the specified directory and workspace.

Arguments provided: $ARGUMENTS

Steps:
1. Parse arguments to extract DIR and WORKSPACE
2. Change to the specified directory
3. Run terraform init if needed
4. Select workspace if specified
5. Run terraform plan
6. Summarize the plan output with focus on:
   - Resources to be added/changed/destroyed
   - IAM changes
   - Network changes
   - Cost implications
7. DO NOT run terraform apply

Use the tf_plan_only skill as guidance (see skills/tf_plan_only.md).
```

**Key Features**:
- Frontmatter with metadata (optional but recommended)
- `$ARGUMENTS` placeholder for user input
- Full prompt body in markdown
- `allowed-tools` restricts which tools the command can use
- `model` can force a specific model for the command

### Hooks Format

**Location**: Executable scripts, configured in `.claude/settings.json`

**Configuration**: `.claude/settings.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(terraform apply:*)|Bash(kubectl apply:*)",
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
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "hooks/post_telemetry.sh"
          }
        ]
      }
    ]
  }
}
```

**Hook Script Example**: `hooks/pre_safety_check.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Read input JSON from stdin
INPUT=$(cat)

# Extract tool name and input
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input')

# Safety check logic
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command')

  # Check for dangerous operations
  if [[ "$COMMAND" =~ "terraform apply" ]] || [[ "$COMMAND" =~ "kubectl apply" ]]; then
    # Block and require approval
    cat <<EOF
{
  "continue": false,
  "stopReason": "This operation requires explicit approval. Type 'APPROVED: terraform apply' to proceed.",
  "systemMessage": "⚠️  Blocked: High-risk operation detected"
}
EOF
    exit 0
  fi
fi

# Allow operation to continue
cat <<EOF
{
  "continue": true
}
EOF
```

**Input JSON Schema** (received via stdin):

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/Users/cartine/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "terraform plan",
    "description": "Run terraform plan"
  }
}
```

**Output JSON Schema**:

```json
{
  "continue": true|false,          // Whether to continue execution
  "stopReason": "string",          // Message shown if continue=false
  "suppressOutput": true|false,    // Hide stdout from transcript
  "systemMessage": "string",       // Optional warning/info message
  "decision": "approve"|"block",   // PreToolUse specific
  "reason": "string"               // Explanation for decision
}
```

**Advanced: Tool Input Modification** (v2.0.10+)

PreToolUse hooks can modify tool inputs:

```bash
#!/usr/bin/env bash
INPUT=$(cat)

# Modify the tool input
MODIFIED=$(echo "$INPUT" | jq '.tool_input.command = "terraform plan -no-color"')

# Output the modified tool input
echo "$MODIFIED" | jq '.tool_input'
```

## Correct Structure for Osterman Template

### Recommended Directory Layout

```
osterman/                            # Template root (copy to ~/.claude)
├── .gitignore
├── README.md                        # Installation and usage guide
├── CLAUDE.md                        # Project-level guidelines (optional for ~/.claude)
├── SPECIFICATION.md                 # This document
├── EXECUTION.md                     # Original execution plan
├── PROMPTING_GUIDE.md              # How to use the agents
├── RISK_REGISTER.md                # Risk categories
│
├── agents/                          # Agent definitions (lean prompts)
│   ├── README.md                    # Explains agent system
│   ├── pe.md                        # Production Engineering
│   ├── tl.md                        # Team Lead
│   ├── swe.md                       # Software Engineer
│   ├── test-engineer.md
│   ├── code-debugger.md
│   └── software-architect.md
│
├── commands/                        # ⚠️ MUST BE HERE, NOT IN .claude/commands/
│   ├── README.md                    # Explains command system
│   ├── pe-plan.md                   # /pe-plan command
│   ├── pe-apply.md                  # /pe-apply command
│   ├── tl-review.md                 # /tl-review command
│   ├── tl-triage.md                 # /tl-triage command
│   ├── swe-impl.md                  # /swe-impl command
│   ├── test-health.md               # /test-health command
│   ├── dbg.md                       # /dbg command
│   └── arch-plan.md                 # /arch-plan command
│
├── hooks/                           # Executable hook scripts
│   ├── README.md                    # Explains hook system
│   ├── pre_safety_check.sh          # PreToolUse safety check
│   ├── post_telemetry.sh            # PostToolUse telemetry
│   └── examples/                    # Example hooks
│       ├── pre_terraform_guard.sh
│       ├── pre_dry_run_enforcer.sh
│       └── post_token_tracker.sh
│
├── skills/                          # Documentation (not executable)
│   ├── README.md                    # Explains skills are patterns
│   └── ... (current files are fine as documentation)
│
├── bin/                             # Helper scripts (unchanged)
│   └── ... (current files are fine)
│
└── settings.json.example            # Example settings configuration
```

**IMPORTANT**: When installing to `~/.claude`, the structure becomes:

```
~/.claude/
├── agents/
├── commands/      # Slash commands go here
├── hooks/
├── skills/
├── bin/
└── settings.json  # User creates from settings.json.example
```

### File-by-File Specifications

#### 1. Slash Commands

**Location**: `commands/pe-plan.md`

```markdown
---
description: Run Terraform plan-only analysis with risk summary
argument-hint: DIR=<path> [WORKSPACE=<name>]
allowed-tools: Bash(terraform:*), Bash(make:*), Bash(cd:*), Read, Grep
model: claude-3-5-sonnet-20241022
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
   - Select workspace if WORKSPACE is specified

3. **Execute Plan**
   - Run `terraform plan` (never apply)
   - Prefer using project Makefile/Taskfile targets if they exist
   - You may use `bin/tf-plan-only` helper script

4. **Risk Analysis**
   Summarize the plan with focus on:
   - **Summary**: Total resources to add/change/destroy
   - **IAM Changes**: New roles, policies, permission modifications
   - **Network Changes**: VPC, subnet, security group, route changes
   - **Data Resources**: Database, storage, queue modifications
   - **Cost Impact**: New paid resources or scale changes
   - **Unintended Destroys**: Flag any resource deletions for review

5. **Output Format**
   ```markdown
   ## Terraform Plan Summary

   **Directory**: ...
   **Workspace**: ...

   ### Changes
   - **Add**: X resources
   - **Change**: Y resources
   - **Destroy**: Z resources

   ### Risk Assessment
   [Critical/High/Medium/Low]

   ### Key Changes
   - ...

   ### Recommendations
   - ...
   ```

6. **Safety Guardrails**
   - NEVER run `terraform apply`
   - If user requests apply, respond: "Apply requires explicit approval. Use /pe-apply or manually run terraform apply."

## Reference Documentation
- Skills: `skills/tf_plan_only.md`
- Agent: `agents/pe.md`
- Safety: `CLAUDE.md` Autonomy Policy
```

**Create Similar Files For**:
- `commands/pe-apply.md` - Confirm-first apply flow
- `commands/tl-review.md` - PR review and optional merge
- `commands/tl-triage.md` - Issue triage and dependency detection
- `commands/swe-impl.md` - Feature implementation workflow
- `commands/test-health.md` - Test health analysis
- `commands/dbg.md` - Debugging workflow
- `commands/arch-plan.md` - Architecture planning

#### 2. Hooks

**Location**: `hooks/pre_safety_check.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook to enforce safety guardrails
# Blocks high-risk operations and requires explicit approval

# Read input from stdin
INPUT=$(cat)

# Check if jq is available
if ! command -v jq &> /dev/null; then
  # Fallback: allow operation if jq is not available
  echo '{"continue": true}'
  exit 0
fi

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

# Function to block with message
block_operation() {
  local reason="$1"
  cat <<EOF
{
  "continue": false,
  "stopReason": "${reason}",
  "systemMessage": "⚠️  BLOCKED: ${reason}"
}
EOF
  exit 0
}

# Function to allow operation
allow_operation() {
  cat <<EOF
{
  "continue": true
}
EOF
  exit 0
}

# Safety checks for Bash commands
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

  # Check for terraform apply
  if [[ "$COMMAND" =~ terraform[[:space:]]+apply ]]; then
    block_operation "terraform apply requires explicit approval. High-risk infrastructure change detected."
  fi

  # Check for kubectl apply/delete in non-kind contexts
  if [[ "$COMMAND" =~ kubectl[[:space:]]+(apply|delete) ]] && [[ ! "$COMMAND" =~ --context.*kind ]]; then
    block_operation "kubectl apply/delete in production context requires explicit approval."
  fi

  # Check for destructive operations
  if [[ "$COMMAND" =~ rm[[:space:]]+-rf ]] || [[ "$COMMAND" =~ rm[[:space:]].*-r.*-f ]]; then
    block_operation "Recursive force delete (rm -rf) requires explicit approval."
  fi

  # Check for database operations
  if [[ "$COMMAND" =~ (psql|mysql|mongo).*DROP ]]; then
    block_operation "Database DROP operations require explicit approval."
  fi

  # Check for secret/credential operations
  if [[ "$COMMAND" =~ aws[[:space:]]+(iam|secretsmanager|kms) ]]; then
    block_operation "AWS IAM/Secrets/KMS operations require explicit approval."
  fi
fi

# Allow operation by default
allow_operation
```

**Location**: `hooks/post_telemetry.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook for telemetry
# Logs tool usage for analysis

INPUT=$(cat)

# Extract basic information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log to telemetry file if desired
TELEMETRY_FILE="${HOME}/.claude/telemetry.jsonl"
if [[ -n "${CLAUDE_TELEMETRY:-}" ]]; then
  mkdir -p "$(dirname "$TELEMETRY_FILE")"
  echo "{\"timestamp\":\"$TIMESTAMP\",\"session\":\"$SESSION_ID\",\"tool\":\"$TOOL_NAME\"}" >> "$TELEMETRY_FILE"
fi

# Always continue
cat <<EOF
{
  "continue": true,
  "suppressOutput": true
}
EOF
```

#### 3. Settings Configuration

**Location**: `settings.json.example`

```json
{
  "hooks": {
    "PreToolUse": [
      {
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
        "matcher": "Bash(rm -rf:*)|Bash(DROP:*)",
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
      "Bash(npm:*)",
      "Bash(make:*)",
      "Bash(terraform init:*)",
      "Bash(terraform plan:*)",
      "Bash(gh:*)",
      "Read",
      "Grep",
      "Glob"
    ],
    "ask": [
      "Bash(terraform apply:*)",
      "Bash(kubectl:*)",
      "Write",
      "Edit"
    ],
    "deny": [
      "Bash(rm -rf /:*)"
    ]
  },
  "env": {
    "CLAUDE_TELEMETRY": "1"
  }
}
```

**Location**: `settings.local.json.example`

```json
{
  "comment": "Copy to settings.local.json and customize for your machine",
  "permissions": {
    "allow": [
      "Bash(test -d /Users/YOUR_USERNAME/.claude)"
    ]
  }
}
```

#### 4. Agent Files (Minor Updates)

Agents are mostly correct but need clarification that skills/hooks are references, not executable.

**Update**: `agents/pe.md`

```markdown
---
name: pe
description: Production Engineering hybrid agent for cloud/infra/devops tasks with safe autonomy for plan-only/analysis and confirm-first for high-risk operations.
model: claude-3-5-sonnet-20241022
autonomy: true
---

# Production Engineering Agent (pe)

## When To Use
- Terraform planning and infra reviews, CI/CD pipeline diagnostics, container/K8s configuration, and any production engineering activity.

## Operating Modes
- **Safe Autonomy**: For plan-only, diff/review, CI diagnosis — proceeds automatically.
- **Confirm-First**: For applies, destructive or cost-impacting changes — always pauses for explicit approval per guardrails.

## What I Do Autonomously
- Run Terraform plan and analyze risks
- Review infrastructure changes for IAM/network/cost impacts
- Investigate CI/CD failures and propose fixes
- Analyze Kubernetes configurations for issues
- Scope relevant infrastructure code for context

## Approval Required For
- `terraform apply` operations
- `kubectl apply/delete` in production contexts
- IAM policy changes
- DNS/SSL/CDN modifications
- Database schema changes
- Secret rotations
- Any operation with significant cost or blast radius

## Available Skills (Reference Documentation)
Skills are documented patterns to follow, not executable functions:
- `skills/tf_plan_only.md` - Terraform plan workflow
- `skills/infra_change_review.md` - Infrastructure review checklist
- `skills/ci_fail_investigate.md` - CI failure diagnosis
- `skills/context_scoper.md` - Efficient context gathering
- `skills/diff_summarizer.md` - Large diff summarization

## Safety Hooks
The following hooks automatically enforce guardrails:
- `pre_safety_check.sh` - Blocks high-risk operations
- `post_telemetry.sh` - Logs operations for audit

## References
- CLAUDE.md: Autonomy Policy, Safety Guardrails, Token Usage Policy
- RISK_REGISTER.md: Risk categories and thresholds
- Use `/pe-plan` and `/pe-apply` slash commands for common workflows
```

#### 5. Documentation Files

**Location**: `commands/README.md`

```markdown
# Slash Commands

Slash commands are custom prompts you can invoke with `/command-name` syntax.

## Location
Commands must be in `~/.claude/commands/` when installed globally, or `.claude/commands/` for project-specific commands.

## Format
Each command is a Markdown file with optional YAML frontmatter:

```markdown
---
description: Brief description shown in /help
argument-hint: [arg1] [arg2]
allowed-tools: Bash(git:*), Read, Write
model: claude-3-5-sonnet-20241022
---

Command prompt goes here.

Use $ARGUMENTS to access user input.
```

## Available Commands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `/pe-plan` | Terraform plan analysis | DIR=<path> [WORKSPACE=<name>] |
| `/pe-apply` | Terraform apply with approval | DIR=<path> [WORKSPACE=<name>] |
| `/tl-review` | PR review and optional merge | REPO=<org/name> PR=<num> |
| `/tl-triage` | Issue triage and dependencies | REPO=<org/name> |
| `/swe-impl` | Feature implementation | TASK="<desc>" [SPEC=<link>] |
| `/test-health` | Test health report | (none) |
| `/dbg` | Debugging workflow | <description> |
| `/arch-plan` | Architecture planning | FEATURE="<desc>" |

## Usage Examples

```bash
/pe-plan DIR=./terraform/staging WORKSPACE=staging
/tl-review REPO=myorg/myrepo PR=123
/swe-impl TASK="add user authentication" SPEC=https://docs.example.com/auth
```

## Creating New Commands

1. Create a new `.md` file in `commands/`
2. Add frontmatter with metadata
3. Write the prompt body
4. Use `$ARGUMENTS` to access user input
5. Test with `/your-command-name`
```

**Location**: `hooks/README.md`

```markdown
# Hooks

Hooks are executable scripts that run automatically before or after tool executions.

## Types

- **PreToolUse**: Runs before a tool is executed, can block or modify the tool call
- **PostToolUse**: Runs after a tool executes, can log or trigger side effects

## Configuration

Hooks are configured in `~/.claude/settings.json`:

```json
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
  }
}
```

## Input Format

Hooks receive JSON via stdin:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/Users/username/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "terraform plan",
    "description": "Run terraform plan"
  }
}
```

## Output Format

Hooks output JSON to stdout:

```json
{
  "continue": true,
  "stopReason": "Optional message if blocked",
  "suppressOutput": false,
  "systemMessage": "Optional warning/info"
}
```

## Available Hooks

- `pre_safety_check.sh` - Blocks high-risk operations
- `post_telemetry.sh` - Logs tool usage for analysis

## Creating New Hooks

1. Create executable script in `hooks/`
2. Read JSON from stdin
3. Perform check/operation
4. Output decision JSON to stdout
5. Configure in `settings.json`
6. Test with matching tool calls
```

**Location**: `skills/README.md`

```markdown
# Skills

Skills are documented patterns and workflows for agents to follow. They are NOT executable code.

## Purpose

Skills provide:
- Reusable workflow templates
- Consistent procedures across agents
- Token-efficient reference documentation
- Best practices for common tasks

## Format

Each skill is a Markdown file with YAML frontmatter:

```yaml
---
name: skill_name
description: What the skill does
inputs: { required: [...], optional: [...] }
outputs: { ... }
dependencies: [ tools/CLIs needed ]
safety: Safety considerations
steps:
  - Step 1
  - Step 2
tooling:
  - Commands or APIs used
---
```

## How Agents Use Skills

Agents reference skills in their documentation:
- "Use the `tf_plan_only` skill as guidance"
- "Follow the workflow in `impl_branch_workflow.md`"

Skills are prompts and procedures, not callable functions.

## Available Skills

### GitHub Management
- `gh_issue_triage.md` - Issue triage workflow
- `gh_dependency_detect.md` - Dependency detection
- `gh_pr_review.md` - PR review checklist
- `gh_pr_merge.md` - Merge workflow

### Infrastructure
- `tf_plan_only.md` - Terraform plan-only workflow
- `infra_change_review.md` - Infrastructure review checklist

### Development
- `impl_branch_workflow.md` - Feature implementation workflow
- `context_scoper.md` - Context gathering best practices
- `diff_summarizer.md` - Diff summarization patterns

### Testing & Quality
- `test_health_report.md` - Test health analysis
- `ci_fail_investigate.md` - CI failure diagnosis

### Architecture
- `arch_integration_plan.md` - Integration planning template
```

## Priority Fixes Needed

### Phase 1: Critical Fixes (MUST HAVE)

1. **Create `.claude/commands/` Directory with Slash Commands**
   - Priority: CRITICAL
   - Create `commands/` directory (note: NOT `.claude/commands/` in the repo)
   - Create 8 command files (pe-plan, pe-apply, tl-review, tl-triage, swe-impl, test-health, dbg, arch-plan)
   - Each file must have proper frontmatter and $ARGUMENTS handling
   - Files: `commands/*.md` (8 files)

2. **Create Executable Hook Scripts**
   - Priority: CRITICAL
   - Create `hooks/pre_safety_check.sh` (safety guardrails)
   - Create `hooks/post_telemetry.sh` (telemetry logging)
   - Make scripts executable (`chmod +x`)
   - Ensure proper JSON input/output handling
   - Files: `hooks/*.sh` (2 files)

3. **Create Proper Settings Configuration**
   - Priority: CRITICAL
   - Create `settings.json.example` with hook configurations
   - Update `settings.local.json.example` with better examples
   - Add comprehensive permissions, tool matchers, timeouts
   - Files: `settings.json.example`, `settings.local.json.example`

### Phase 2: Documentation Updates

4. **Add README Files to Subdirectories**
   - Priority: HIGH
   - Create `commands/README.md` explaining slash command system
   - Create `hooks/README.md` explaining hook system with examples
   - Update `skills/README.md` clarifying they're documentation only
   - Update `agents/README.md` explaining agent selection
   - Files: `commands/README.md`, `hooks/README.md`, `skills/README.md`, `agents/README.md`

5. **Update Main Documentation**
   - Priority: HIGH
   - Update `README.md` with correct installation instructions
   - Update references to slash commands (commands/ not hooks/command_router.md)
   - Add troubleshooting section
   - Clarify what's executable vs documentation
   - Files: `README.md`, `PROMPTING_GUIDE.md`

6. **Update Agent Files**
   - Priority: MEDIUM
   - Update all agent frontmatter to clarify skills/hooks are references
   - Add section explaining what's autonomous vs requires approval
   - Reference the correct slash commands
   - Files: `agents/*.md` (6 files)

### Phase 3: Cleanup

7. **Remove/Archive Obsolete Files**
   - Priority: LOW
   - Archive `hooks/command_router.md` (replaced by slash commands)
   - Keep other hook .md files as documentation but rename to clarify
   - Update COMMANDS.md to reference slash commands
   - Files: Move `hooks/*.md` to `hooks/docs/` or remove

8. **Add Example Hooks**
   - Priority: LOW
   - Create `hooks/examples/` directory
   - Add example hooks for common scenarios
   - Document hook development workflow
   - Files: `hooks/examples/*.sh` (3-5 examples)

## Installation Instructions

### For Testing (Project-Local)

```bash
# In the osterman directory
mkdir -p .claude/commands .claude/hooks
cp commands/* .claude/commands/
cp hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
cp settings.json.example .claude/settings.json

# Edit .claude/settings.json to adjust paths if needed
# Open Claude Code in this directory
```

### For Global Installation

```bash
# Backup existing configuration
if [ -d ~/.claude ]; then
  mv ~/.claude ~/.claude.backup-$(date +%Y%m%d%H%M%S)
fi

# Clone or copy osterman to a working directory
git clone <repo-url> ~/claude-config
cd ~/claude-config

# Create the .claude structure
mkdir -p ~/.claude/commands ~/.claude/hooks ~/.claude/skills ~/.claude/agents

# Copy files
cp -r commands/* ~/.claude/commands/
cp -r hooks/*.sh ~/.claude/hooks/
cp -r skills/* ~/.claude/skills/
cp -r agents/* ~/.claude/agents/
cp -r bin ~/.claude/

# Make scripts executable
chmod +x ~/.claude/hooks/*.sh
chmod +x ~/.claude/bin/*

# Create settings from example
cp settings.json.example ~/.claude/settings.json

# Edit settings
vim ~/.claude/settings.json  # Adjust paths, permissions, etc.

# Add bin to PATH (optional but recommended)
echo 'export PATH="$HOME/.claude/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Test installation
ls ~/.claude/commands/  # Should show slash command files
claude --version        # Verify Claude Code is installed
```

### Verification

```bash
# Start Claude Code in any project
cd ~/myproject
claude

# In Claude chat, try:
/help              # Should list your custom commands
/pe-plan --help    # Should show pe-plan command
```

## Testing Plan

### Test Slash Commands

1. Test `/pe-plan` with valid Terraform directory
2. Test `/tl-review` with valid REPO and PR
3. Verify `$ARGUMENTS` are correctly parsed
4. Verify allowed-tools restrictions work
5. Verify custom model selection works

### Test Hooks

1. Trigger a Bash command that should be blocked (terraform apply)
2. Verify hook script receives correct JSON input
3. Verify hook script returns correct JSON output
4. Verify operation is blocked with proper message
5. Test telemetry hook logs correctly
6. Verify hook timeout works

### Test Agent Selection

1. Create a prompt using each agent
2. Verify agent has access to referenced skills documentation
3. Verify agents follow their autonomy policies
4. Verify agents can invoke slash commands

### Test bin Scripts

1. Test each bin script with required env vars
2. Verify DRY_RUN defaults work
3. Verify scripts integrate with slash commands
4. Verify scripts work when called directly

## Common Issues and Solutions

### Slash Commands Not Appearing

**Problem**: `/pe-plan` shows "Unknown command"

**Solutions**:
- Verify files are in `~/.claude/commands/` (or `.claude/commands/` for project)
- Check file names match command names (pe-plan.md → /pe-plan)
- Verify files have `.md` extension
- Restart Claude Code after adding commands

### Hooks Not Running

**Problem**: Dangerous commands not being blocked

**Solutions**:
- Verify hook scripts are executable: `chmod +x hooks/*.sh`
- Check `settings.json` has correct hook configuration
- Verify matcher patterns are correct (use wildcards properly)
- Test hook script manually: `echo '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | hooks/pre_safety_check.sh`
- Check hook script returns valid JSON

### Hook Script Errors

**Problem**: Hook fails with jq errors or JSON parse errors

**Solutions**:
- Install jq: `brew install jq` or `apt-get install jq`
- Verify input JSON is valid
- Add error handling for missing fields
- Use fallback behavior if jq is unavailable

### Permissions Issues

**Problem**: Claude asks for permission for every operation

**Solutions**:
- Review `permissions.allow` in settings.json
- Use wildcards for tool patterns: `Bash(git:*)` not `Bash(git)`
- Add commonly used tools to allow list
- Use `ask` only for high-risk operations

## Success Criteria

The configuration is working correctly when:

1. All 8 slash commands appear in `/help` output
2. Slash commands execute with proper agent context
3. Pre-safety hook blocks `terraform apply` with clear message
4. Pre-safety hook blocks `kubectl apply` in non-kind contexts
5. Post-telemetry hook logs operations without errors
6. Agents can reference skills documentation effectively
7. bin scripts work both directly and via slash commands
8. Settings configuration is clear and well-documented
9. Installation process is smooth and documented
10. Template can be copied to ~/.claude and works immediately

## Summary of Key Changes

| Component | Current State | Required State | Priority |
|-----------|---------------|----------------|----------|
| Slash Commands | In `hooks/command_router.md` | In `commands/*.md` (8 files) | CRITICAL |
| Hooks | Markdown docs in `hooks/` | Executable scripts in `hooks/` | CRITICAL |
| Settings | Minimal permissions only | Full hook configuration + permissions | CRITICAL |
| Documentation | Mixed executable/docs | Clear separation | HIGH |
| Agents | Reference non-existent hooks | Reference docs + working hooks | MEDIUM |
| Skills | Good as-is | Add clarifying README | MEDIUM |
| Bin scripts | Good as-is | No changes needed | N/A |

## Next Steps

1. Review this specification with project stakeholders
2. Implement Phase 1 (Critical) changes
3. Test each component thoroughly
4. Implement Phase 2 (Documentation) changes
5. Validate installation process
6. Create Phase 3 (Cleanup) improvements
7. Document lessons learned
8. Prepare for public release

## References

- Official Hooks Documentation: https://docs.claude.com/en/docs/claude-code/hooks
- Official Slash Commands Documentation: https://docs.claude.com/en/docs/claude-code/slash-commands
- Claude Code Best Practices: https://www.anthropic.com/engineering/claude-code-best-practices
- Original Specification: `EXECUTION.md`
- Git Repository: /Users/cartine/osterman/
