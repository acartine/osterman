# Osterman .claude Configuration - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Claude Code User                         │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ├─ Invokes ──> Skills (ship_with_review, tf_plan_only, etc.)
                   ├─ Selects ──> Agents (pe, swe, doc)
                   └─ Triggers ─> Tool Calls (Bash, Write, Read, etc.)
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Execution Layer                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────┐    ┌───────────────┐    ┌────────────────┐ │
│  │     Skills     │    │    Agents     │    │     Hooks      │ │
│  │   (skills/)    │    │  (agents/)    │    │   (hooks/)     │ │
│  └────────────────┘    └───────────────┘    └────────────────┘ │
│         │                      │                      │          │
│         │                      │                      │          │
│         ▼                      ▼                      ▼          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         Prompt Processing & Tool Execution              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                               ▼
                   ┌───────────────────────┐
                   │   Tool Call (Bash,    │
                   │   Write, Read, etc.)  │
                   └───────────────────────┘
                               │
                  ┌────────────┴────────────┐
                  ▼                         ▼
         ┌────────────────┐       ┌────────────────┐
         │  PreToolUse    │       │  PostToolUse   │
         │     Hooks      │       │     Hooks      │
         │   (Validate/   │       │   (Log/Track)  │
         │    Block/      │       │                │
         │    Modify)     │       │                │
         └────────────────┘       └────────────────┘
                  │                         │
                  │ continue:true           │
                  ▼                         ▼
         ┌────────────────┐       ┌────────────────┐
         │   Execute      │       │   Telemetry    │
         │     Tool       │──────>│    & Logs      │
         └────────────────┘       └────────────────┘
                  │
                  ▼
         ┌────────────────┐
         │    Result      │
         │   Returned     │
         └────────────────┘
```

## Component Responsibilities

### 1. Skills (`skills/`)

**Type**: Markdown files with workflow documentation
**Location**: `~/.claude/skills/*.md`
**Invocation**: User references skill in conversation or uses Skill tool

```
User: "Use the ship_with_review skill to implement issue #123"
  │
  ▼
skills/ship_with_review.md loaded as context
  │
  ▼
Agent follows documented workflow
  │
  ▼
Task completed per skill guidance
```

**Responsibilities**:
- Document reusable workflows and patterns
- Provide step-by-step procedures
- List required tools and dependencies
- Define safety considerations

**Available Skills**:
- `ship_with_review` - End-to-end issue-to-merge workflow
- `tf_plan_only` - Terraform plan (safe, no apply)
- `orientation` - Orient to codebase structure
- `documentation` - Create/update documentation
- `gh_issue_create`, `gh_pr_merge`, `gh_pr_view` - GitHub workflows
- `rebase`, `pull_main` - Git operations
- `iac`, `infra_change_review` - Infrastructure workflows
- `stability_checks` - Run sanity/stability checks

### 2. Agents (`agents/`)

**Type**: Markdown files with role definitions
**Location**: `~/.claude/agents/*.md`
**Selection**: User chooses agent or agent is invoked by skill

**Available Agents**:
- `pe` - Production Engineering (infra/cloud/terraform)
- `swe` - Software Engineering (implementation)
- `doc` - Documentation

```
User selects "pe" agent
  │
  ▼
agents/pe.md loaded as system context
  │
  ▼
Agent behavior, constraints, and references applied
  │
  ▼
Agent executes user's task with this context
```

**Responsibilities**:
- Define role-specific behavior and expertise
- Specify autonomy policies
- Reference skills and hooks for guidance
- Provide context on when to use this agent

**Example Flow**:
```
Agent: pe
    ↓
Load: agents/pe.md (Production Engineering context)
    ↓
Apply: Autonomy policies, skill references, safety guidelines
    ↓
Execute: User task with PE expertise and constraints
    ↓
Reference: skills/tf_plan_only.md for workflow guidance
```

### 3. Hooks (`hooks/`)

**Type**: Executable scripts (shell, python, etc.)
**Location**: `~/.claude/hooks/*.sh`
**Configuration**: `~/.claude/settings.json`
**Invocation**: Automatic, triggered by tool calls

```
Agent attempts: Bash("terraform apply")
  │
  ▼
settings.json: Match "Bash(terraform apply:*)"
  │
  ▼
Execute: hooks/pre_safety_check.sh
  │
  ├─> JSON Input: {"tool_name": "Bash", "tool_input": {...}}
  │
  ├─> Hook Logic: Check if dangerous operation
  │
  └─> JSON Output: {"continue": false, "stopReason": "..."}
  │
  ▼
Operation blocked or allowed based on hook response
```

**Responsibilities**:
- Validate tool calls before execution (PreToolUse)
- Log or trigger side effects after execution (PostToolUse)
- Modify tool inputs for safety (e.g., add --dry-run flags)
- Enforce safety policies automatically

**Example Flow**:
```
Tool Call: Bash("terraform apply")
    ↓
Match: PreToolUse hook with matcher "Bash(terraform apply:*)"
    ↓
Execute: hooks/pre_safety_check.sh
    ↓
Input: {"tool_name": "Bash", "tool_input": {"command": "terraform apply"}}
    ↓
Check: Is this a high-risk operation? YES
    ↓
Output: {"continue": false, "stopReason": "Requires approval"}
    ↓
Result: Tool call blocked, user sees approval message
```

### 4. Skill Invocation

Skills can be invoked in multiple ways:

1. **Natural language**: "Use the ship_with_review skill to implement issue #123"
2. **Skill tool**: The Skill tool can directly invoke skills
3. **Agent reference**: Agents reference skills for workflow guidance

**Example Flow**:
```
User: "Use tf_plan_only for ./infra"
    ↓
Load: skills/tf_plan_only.md
    ↓
Agent follows documented steps
    ↓
Execute: 1. Init, 2. Select workspace, 3. Run plan, 4. Summarize
    ↓
Return: Plan output and summary to user
```

### 5. Bin Scripts (`bin/`)

**Type**: Executable shell scripts
**Location**: `~/.claude/bin/*`
**Invocation**: Called by agents or directly by users

```
Agent needs: PR review data
  │
  ▼
Execute: bin/gh-pr-review
  │
  ▼
Script: Fetch PR data via gh CLI
  │
  ▼
Return: Formatted output to agent
```

**Responsibilities**:
- Encapsulate complex CLI operations
- Provide reusable utilities for common tasks
- Handle environment variables and defaults
- Enforce DRY_RUN patterns for safety

**Example Flow**:
```
Command: REPO=org/name PR=123 bin/gh-pr-review
    ↓
Validate: REPO and PR are set
    ↓
Execute: gh pr view ... --json
    ↓
Execute: gh pr diff ...
    ↓
Format: Output for easy consumption
    ↓
Return: PR summary and diff to caller
```

## Data Flow Examples

### Example 1: User Invokes tf_plan_only Skill

```
1. User types: "Use tf_plan_only for ./infra workspace staging"

2. Claude Code:
   - Loads skills/tf_plan_only.md
   - Agent follows documented workflow

3. Agent (pe):
   - Reads agents/pe.md for context
   - References skills/tf_plan_only.md for workflow
   - Plans to execute: Bash("terraform plan")

4. PreToolUse Hook:
   - settings.json matches: Bash(terraform plan:*)
   - Executes: hooks/pre_safety_check.sh
   - Input: {"tool_name": "Bash", "tool_input": {"command": "terraform plan"}}
   - Output: {"continue": true}  (plan is safe)

5. Tool Execution:
   - Bash("cd ./infra && terraform plan") executes
   - Output returned to agent

6. PostToolUse Hook:
   - Executes: hooks/post_telemetry.sh
   - Logs: Operation to telemetry file
   - Output: {"continue": true, "suppressOutput": true}

7. Agent:
   - Receives terraform plan output
   - Analyzes and summarizes per skill guidance
   - Returns summary to user
```

### Example 2: User Attempts Dangerous Operation

```
1. User types: "Run terraform apply in production"

2. Agent (pe):
   - Interprets request
   - Plans to execute: Bash("terraform apply")

3. PreToolUse Hook:
   - settings.json matches: Bash(terraform apply:*)
   - Executes: hooks/pre_safety_check.sh
   - Input: {"tool_name": "Bash", "tool_input": {"command": "terraform apply"}}
   - Check: Dangerous operation detected
   - Output: {
       "continue": false,
       "stopReason": "terraform apply requires explicit approval",
       "systemMessage": "⚠️  BLOCKED: High-risk operation"
     }

4. Claude Code:
   - Receives continue: false
   - Blocks tool execution
   - Shows user the stopReason message

5. User:
   - Sees: "terraform apply requires explicit approval"
   - Can choose to:
     a) Grant explicit approval
     b) Cancel operation
```

### Example 3: Agent Uses Skill Documentation

```
1. User: "Use ship_with_review to implement issue #123"

2. Task: End-to-end issue implementation

3. Agent (swe):
   - Loads agents/swe.md for role context
   - References skills/ship_with_review.md for workflow
   - Reads documented steps:
     1. Read GitHub issue
     2. Create feature branch in worktree
     3. Implement solution
     4. Create PR and trigger review
     5. Iterate on feedback
     6. Merge when approved

4. Agent follows steps:
   - Fetches issue details via gh CLI
   - Creates worktree and implements
   - Creates PR, triggers Codex review
   - Iterates on NEEDS_WORK feedback

5. Agent references:
   - skills/ship_with_review.md for workflow
   - skills/gh_pr_merge.md for merge procedure
   - CLAUDE.md for autonomy policies
```

## Configuration Hierarchy

```
~/.claude/                              # Global config (user-level)
├── settings.json                       # Hook config, permissions
├── settings.local.json                 # Machine-specific overrides
│
├── skills/                             # Workflow documentation (primary)
│   ├── ship_with_review.md             # Signature workflow
│   ├── tf_plan_only.md                 # Terraform workflow
│   └── ...
│
├── agents/                             # Agent definitions
│   ├── pe.md                           # Production Engineering
│   ├── swe.md                          # Software Engineering
│   └── doc.md                          # Documentation
│
├── hooks/                              # Executable hooks
│   ├── pre_safety_check.sh             # Safety guardrails
│   └── post_telemetry.sh               # Telemetry logging
│
└── bin/                                # Utility scripts
    ├── gh-pr-review                    # PR review helper
    └── ...

OR

.claude/                                # Project-specific config
├── settings.json                       # Project overrides
├── skills/                             # Project-specific skills
└── ...                                 # (same structure as global)
```

**Resolution Order**:
1. Project `.claude/` (if exists)
2. Global `~/.claude/`
3. Built-in defaults

## Settings.json Structure

```json
{
  "hooks": {
    "PreToolUse": [                     // Runs before tool execution
      {
        "matcher": "Bash(terraform apply:*)",  // Tool pattern to match
        "hooks": [
          {
            "type": "command",
            "command": "hooks/pre_safety_check.sh",  // Script to run
            "timeout": 30000            // Max execution time (ms)
          }
        ]
      }
    ],
    "PostToolUse": [                    // Runs after tool execution
      {
        "matcher": "*",                 // Match all tools
        "hooks": [
          {
            "type": "command",
            "command": "hooks/post_telemetry.sh"
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [                          // Auto-approve these tools
      "Bash(git:*)",
      "Read",
      "Grep"
    ],
    "ask": [                            // Ask user for approval
      "Bash(terraform apply:*)",
      "Write",
      "Edit"
    ],
    "deny": [                           // Never allow
      "Bash(rm -rf /:*)"
    ]
  },
  "env": {                              // Environment variables
    "CLAUDE_TELEMETRY": "1"
  }
}
```

## Component Interaction Matrix

| Component | Can Invoke | Can Reference | Can Modify | Invoked By |
|-----------|-----------|---------------|------------|------------|
| Skill | Agents | Other Skills | Tool Calls | User, Skill tool |
| Agent | Tools, Bin Scripts | Skills, CLAUDE.md | Hooks (indirectly) | User, Skill |
| Hook | N/A | N/A | Tool Inputs | Tool Calls (automatic) |
| Bin Script | CLI Tools | N/A | N/A | Agent, User |

## Security & Safety Layers

```
User Request
    ↓
┌─────────────────────────┐
│  Layer 1: Permissions   │  (settings.json permissions.ask/deny)
└─────────────────────────┘
    ↓ (if allowed)
┌─────────────────────────┐
│  Layer 2: PreToolUse    │  (hooks/pre_safety_check.sh)
│         Hooks           │  - Validate operation
└─────────────────────────┘  - Block high-risk actions
    ↓ (if continue: true)     - Request approval
┌─────────────────────────┐
│  Layer 3: Tool          │  (Bash, Write, Edit, etc.)
│       Execution         │
└─────────────────────────┘
    ↓
┌─────────────────────────┐
│  Layer 4: PostToolUse   │  (hooks/post_telemetry.sh)
│         Hooks           │  - Log operations
└─────────────────────────┘  - Trigger side effects
    ↓
┌─────────────────────────┐
│  Layer 5: Agent         │  - Review results
│      Autonomy           │  - Decide next action
└─────────────────────────┘  - Follow autonomy policy
    ↓
Result to User
```

## Summary

- **Skills**: Reusable workflow documentation (primary interface)
- **Agents**: Role-specific system context and behavior
- **Hooks**: Executable scripts for validation and telemetry
- **Bin Scripts**: Utility scripts for complex operations

**Key Principle**: Separation of concerns
- Skills define **what** to do and **how** to do it (workflows)
- Agents define **who** does it (roles)
- Hooks define **safety** (guardrails)
- Bin scripts **encapsulate** complex operations
