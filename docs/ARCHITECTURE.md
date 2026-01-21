# Osterman .claude Configuration - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Claude Code User                         │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ├─ Invokes ──> Slash Commands (/pe-plan, /tl-triage)
                   ├─ Selects ──> Agents (pe, tl, swe, etc.)
                   └─ Triggers ─> Tool Calls (Bash, Write, Read, etc.)
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Execution Layer                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────┐    ┌───────────────┐    ┌────────────────┐ │
│  │ Slash Commands │    │    Agents     │    │     Hooks      │ │
│  │  (commands/)   │    │  (agents/)    │    │   (hooks/)     │ │
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

### 1. Slash Commands (`commands/`)

**Type**: Markdown files with prompts
**Location**: `~/.claude/commands/*.md`
**Invocation**: User types `/command-name` in chat

```
User: /pe-plan DIR=./terraform WORKSPACE=staging
  │
  ▼
commands/pe-plan.md loaded as prompt
  │
  ▼
Prompt expanded with $ARGUMENTS replaced
  │
  ▼
Agent executes with expanded prompt
```

**Responsibilities**:
- Define custom prompts for common workflows
- Accept and parse user arguments via `$ARGUMENTS`
- Specify allowed tools and model preferences
- Provide structured guidance to agents

**Example Flow**:
```
/pe-plan DIR=./infra WORKSPACE=staging
    ↓
Load: commands/pe-plan.md
    ↓
Replace: $ARGUMENTS with "DIR=./infra WORKSPACE=staging"
    ↓
Execute: Production Engineering agent with expanded prompt
    ↓
Agent: Runs terraform plan following the prompt instructions
```

### 2. Agents (`agents/`)

**Type**: Markdown files with role definitions
**Location**: `~/.claude/agents/*.md`
**Selection**: User chooses agent or agent is invoked by slash command

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

### 4. Skills (`skills/`)

**Type**: Markdown documentation files
**Location**: `~/.claude/skills/*.md`
**Reference**: Agents read these for workflow guidance

```
Agent needs: Terraform plan workflow
  │
  ▼
Reference: skills/tf_plan_only.md
  │
  ▼
Follow: Steps, tooling, and safety guidance documented
  │
  ▼
Execute: Workflow as documented in skill
```

**Responsibilities**:
- Document reusable workflows and patterns
- Provide step-by-step procedures
- List required tools and dependencies
- Define safety considerations

**Example Flow**:
```
Agent: pe executing terraform plan
    ↓
Reference: skills/tf_plan_only.md
    ↓
Read: Steps, tooling, safety guidelines
    ↓
Follow: 1. Init, 2. Select workspace, 3. Run plan, 4. Summarize
    ↓
Execute: Each step with documented best practices
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

### Example 1: User Runs `/pe-plan`

```
1. User types: /pe-plan DIR=./infra WORKSPACE=staging

2. Claude Code:
   - Loads commands/pe-plan.md
   - Replaces $ARGUMENTS with "DIR=./infra WORKSPACE=staging"
   - Invokes agent "pe" with expanded prompt

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
     b) Use /pe-apply (confirm-first workflow)
     c) Cancel operation
```

### Example 3: Agent Uses Skill Documentation

```
1. User selects: Agent "tl" (Team Lead)

2. Task: Triage open issues

3. Agent (tl):
   - Loads agents/tl.md for role context
   - References skills/gh_issue_triage.md for triage procedure
   - Reads documented steps:
     1. Fetch open issues
     2. Categorize by type
     3. Assess priority
     4. Map dependencies

4. Agent follows steps:
   - Executes: gh issue list (via gh CLI)
   - Categorizes: bug, feature, tech-debt, question
   - Assesses: impact, effort, blockers
   - Maps dependencies between issues

5. Agent references:
   - skills/gh_issue_triage.md for triage workflow
   - skills/context_scoper.md to scope relevant files
   - CLAUDE.md for autonomy policies
```

## Configuration Hierarchy

```
~/.claude/                              # Global config (user-level)
├── settings.json                       # Hook config, permissions
├── settings.local.json                 # Machine-specific overrides
│
├── commands/                           # Slash commands
│   ├── pe-plan.md                      # /pe-plan
│   └── ...
│
├── hooks/                              # Executable hooks
│   ├── pre_safety_check.sh             # Safety guardrails
│   └── post_telemetry.sh               # Telemetry logging
│
├── agents/                             # Agent definitions
│   ├── pe.md                           # Production Engineering
│   └── ...
│
├── skills/                             # Workflow documentation
│   ├── tf_plan_only.md                 # Terraform workflow
│   └── ...
│
└── bin/                                # Utility scripts
    ├── gh-pr-review                    # PR review helper
    └── ...

OR

.claude/                                # Project-specific config
├── settings.json                       # Project overrides
├── commands/                           # Project-specific commands
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
| Slash Command | Agents | Skills, Agents | Tool Calls | User |
| Agent | Tools, Bin Scripts | Skills, CLAUDE.md | Hooks (indirectly) | User, Slash Command |
| Hook | N/A | N/A | Tool Inputs | Tool Calls (automatic) |
| Skill | N/A | N/A | N/A | Agent (read-only) |
| Bin Script | CLI Tools | N/A | N/A | Agent, User, Slash Command |

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

- **Slash Commands**: Custom prompts invoked by `/command-name`
- **Agents**: Role-specific system context and behavior
- **Hooks**: Executable scripts for validation and telemetry
- **Skills**: Documentation for reusable workflows
- **Bin Scripts**: Utility scripts for complex operations

**Key Principle**: Separation of concerns
- Commands define **what** to do (prompts)
- Agents define **who** does it (roles)
- Hooks define **safety** (guardrails)
- Skills define **how** to do it (workflows)
- Bin scripts **encapsulate** complex operations
