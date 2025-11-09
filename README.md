# Osterman Claude Configuration

Production-ready Claude Code configuration for autonomous software development workflows.

## What is this?

The `osterman` .claude configuration provides specialized slash commands, safety hooks, and autonomous agent workflows for professional software development. It implements a secure, efficient approach to infrastructure management, code implementation, PR review, and debugging using Claude Code CLI.

## Why is it called `osterman`?
Before he was Dr. Manhattan, he was Jon Osterman.  We hope someday to be Dr. Manhattan.

## Features

### Slash Commands

Eight specialized commands for common development workflows:

- **`/ship`** - Ship changes quickly: commit, push, create PR, and auto-merge
- **`/test-health`** - Generate test health reports with flaky and slow test analysis
- **`/pe`** - Production Engineering workflows with safety guardrails for infrastructure changes
- **`/tl`** - Team Lead workflows for PR review, issue triage, and merge management
- **`/swe`** - Software Engineering implementation with branch workflow and DRAFT PRs (Sonnet-powered)
- **`/jswe`** - Junior Software Engineering for simple tasks (Haiku-powered, faster and cheaper)
- **`/dbg`** - Code debugging with scoped analysis and fix proposals
- **`/arch`** - Architecture planning and integration design

### Safety Hooks

Two executable hooks that enforce guardrails:

- **`pre_safety_check.sh`** - Blocks dangerous infrastructure operations (terraform apply, kubectl delete, etc.)
- **`post_telemetry.sh`** - Logs tool usage for audit and analysis

### Guardrails

- Blocks destructive operations without explicit approval
- Requires confirmation for production changes
- Prevents accidental infrastructure modifications
- Comprehensive permission controls for 47+ bash commands

### Token Optimization

- Scoped context using ripgrep
- Progressive disclosure patterns
- Skill-based composition
- Summarized diffs and large files

### Recommended Tooling

This configuration recommends using the **shemcp** MCP server for enhanced bash command execution:

- **[shemcp](https://github.com/acartine/shemcp)** - Shell command execution MCP server with improved reliability and performance
- Automatically preferred by agents when available for commands like: `aws`, `az`, `grep`, `sed`, `npm`, `make`, `terraform`, and more
- See [shemcp installation instructions](https://github.com/acartine/shemcp#installation) to set up

**Don't want to use shemcp?** Simply remove the shemcp-related tooling section from the top of `CLAUDE.md` in your configuration. The agents will fall back to standard bash execution.

## Quick Start

### Installation

```bash
# Step 1: Fork the repository on GitHub (recommended)
# Go to https://github.com/ORIGINAL_OWNER/osterman and click "Fork"

# Step 2: Install globally to ~/.claude
mv ~/.claude ~/.claude.backup  # backup existing config if it exists
git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude

# OR install to project .claude directory
cd /path/to/your/project
mv .claude .claude.backup  # backup existing config if it exists
git clone https://github.com/YOUR_USERNAME/osterman.git .claude

# Step 3: Verify installation
cd ~/.claude  # or cd /path/to/project/.claude
make test
```

### Try a Command

```bash
# Ship: Quick commit, push, PR, and merge (the fastest path!)
claude /ship
claude /ship DESC="feat: add user profile export"

# Team Lead: Review and merge a PR
claude /tl review_and_merge 123

# Team Lead: Create a bug report
claude /tl ticket TYPE='bug' DESC='Login fails with OAuth providers'

# Software Engineer: Implement from GitHub issue (Sonnet - for complex tasks)
claude /swe ticket 456

# Software Engineer: Implement with inline spec
claude /swe impl TASK="add-rate-limiting" SPEC="Add rate limiting to API endpoints"

# Junior SWE: Quick bug fix (Haiku - faster and cheaper)
claude /jswe impl TASK="fix-null-check" SPEC="Add null check in getUserById"

# Junior SWE: Simple issue implementation
claude /jswe ticket 42

# Other agents
claude /test-health
claude /pe plan DIR=./infra WORKSPACE=staging
claude /dbg "500 error on /api/users endpoint"
```

### Updating

```bash
# Navigate to your .claude directory
cd ~/.claude  # or cd /path/to/project/.claude

# Pull latest changes
git pull
```

## Agent Reference

### `/tl` - Team Lead Agent

**Purpose**: Autonomous PR review, issue triage, and merge management
**Model**: Sonnet 4.5
**Autonomy**: Full - reviews and merges without formal GitHub approvals

**Operations:**

#### `review` - Comprehensive PR Review
Reviews a PR and posts structured findings as a comment.

```bash
# Review PR in current repo
/tl review 123

# Review PR in specific repo
/tl review 456 REPO=acme/backend

# Alternative syntax
/tl review PR=789 REPO=acme/frontend
```

**What it does:**
- Analyzes correctness, security, performance, tests, docs, code quality
- Categorizes findings: Critical / Important / Suggestions
- Assesses risk level: Low / Medium / High
- Posts review comment with structured feedback
- Includes file:line references for all findings

#### `review_and_merge` - Auto-Merge After Review
Reviews a PR and automatically merges if ready (no formal approval needed).

```bash
# Review and auto-merge PR in current repo
/tl review_and_merge 123

# Review and merge PR in specific repo
/tl review_and_merge 456 REPO=acme/api
```

**What it does:**
- Performs comprehensive review
- If ready: Posts comment with decision marker, verifies CI, merges immediately
- If changes needed: Posts review, monitors for updates, re-reviews automatically
- If discussion needed: Posts comment, waits for manual re-run
- **Note**: Uses comment-based workflow (no formal GitHub approvals)

#### `triage` - Issue Prioritization
Triages open issues and maps dependencies.

```bash
# Triage issues in current repo
/tl triage

# Triage issues in specific repo
/tl triage REPO=acme/backend
```

**What it does:**
- Fetches all open issues
- Categorizes by type: bug, feature, tech-debt, question
- Assesses priority: impact, effort, blockers
- Maps dependencies between issues
- Recommends order of work

#### `ticket` - Create GitHub Issue
Creates a new GitHub issue with proper formatting.

```bash
# Create a bug report
/tl ticket TYPE='bug' DESC='Search function returns incorrect results'

# Request a new feature
/tl ticket TYPE='feature' DESC='Add dark mode support' REPO=acme/frontend

# Other types: enhancement, docs, test, refactor
/tl ticket TYPE='docs' DESC='Document API authentication flow'
```

**What it does:**
- Creates issue with type-specific template
- Auto-formats title and body
- Returns issue URL
- Suggests next steps

---

### `/swe` - Software Engineering Agent

**Purpose**: Complex feature implementation with full workflow
**Model**: Sonnet 4.5
**Autonomy**: Full - implements, tests, creates PRs

**Operations:**

#### `impl` - Feature Implementation
Implements a feature from specification through DRAFT PR.

```bash
# Implement feature with URL spec
/swe impl TASK="user-profile-page" SPEC=https://github.com/acme/specs/issues/42

# Implement feature with inline spec
/swe impl TASK="add-pagination" SPEC="Add pagination to /users endpoint with limit/offset params"

# Implement bug fix
/swe impl TASK="fix-login-redirect" SPEC="After login, redirect to original requested page instead of home"

# Complex feature requiring architectural decisions
/swe impl TASK="oauth-integration" SPEC="Add OAuth2 support for Google and GitHub authentication"
```

**What it does:**
1. **Preparation**: Checks out main, pulls latest, runs compile/tests/smoketests
2. **Branch**: Creates feature branch with descriptive name
3. **Implementation**: Codes according to spec, follows project patterns
4. **Testing**: Runs tests, adds new tests, directly verifies the specific change works
5. **Commit**: Commits with clear message, pushes to remote
6. **PR**: Creates DRAFT PR with summary, test plan, notes
7. **CI**: Monitors checks, fixes failures, marks ready when green
8. **Handoff**: Prompts operator for review approval

#### `ticket` - GitHub Issue Implementation
Implements a feature based on a GitHub issue.

```bash
# Work on GitHub issue #123
/swe ticket 123

# Works on any public or private repo (auto-detects from git remote)
/swe ticket 456
```

**What it does:**
- Auto-detects repository from `git remote`
- Fetches issue title and body via `gh` CLI
- Uses issue number in branch name: `feature/issue-123-short-description`
- Follows same workflow as `impl`
- Automatically includes "Closes #123" in PR body

**When to use SWE:**
- Complex features with multiple integration points
- Architectural changes requiring decisions
- Features with unclear requirements needing exploration
- Security-sensitive implementations
- Performance optimization requiring profiling
- Changes affecting multiple systems

---

### `/jswe` - Junior Software Engineering Agent

**Purpose**: Simple, straightforward implementations (fast and cost-effective)
**Model**: Haiku 4.5 (faster, cheaper than Sonnet)
**Autonomy**: Full - same workflow as swe but optimized for simplicity

**Operations:**

#### `impl` - Simple Implementation
Implements straightforward features and bug fixes.

```bash
# Simple bug fix
/jswe impl TASK="fix-null-check" SPEC="Add null check in getUserById to prevent NPE"

# Small enhancement
/jswe impl TASK="add-logging" SPEC="Add debug logging to payment processing endpoint"

# Straightforward feature
/jswe impl TASK="add-pagination" SPEC="Add pagination to /users endpoint (max 100 per page)"

# Quick typo fix
/jswe impl TASK="fix-error-message" SPEC="Fix typo in validation error message for email field"
```

**What it does:**
- Same 8-step workflow as `/swe` but optimized for speed
- Focuses on simplest working solution
- Follows existing patterns closely
- Escalates to `/swe` if complexity detected

#### `ticket` - Simple GitHub Issue Implementation
Implements a simple feature or bug fix from a GitHub issue.

```bash
# Work on simple GitHub issue #42
/jswe ticket 42

# Quick bug fix from issue
/jswe ticket 99
```

**What it does:**
- Same as `/swe ticket` but with Haiku model
- Better for well-defined, straightforward issues
- Faster execution and lower cost

**When to use JSWE:**
- Simple bug fixes with clear reproduction steps
- Small enhancements to existing features
- Straightforward features with clear specifications
- Code style or formatting improvements
- Documentation updates
- Adding simple validation or error handling
- Small refactoring with clear scope

**When to escalate to SWE:**
- Unclear or conflicting requirements
- Need for architectural decisions
- Multiple integration points or complex dependencies
- Security-sensitive changes
- Changes affecting multiple systems

---

### `/ship` - Ship Command

**Purpose**: Fast path to get changes merged - commit, push, PR, and auto-merge in one command
**Model**: Sonnet 4.5
**Autonomy**: Full - handles branch creation through merge

**Operations:**

#### Quick Ship
Ship local changes with auto-generated or custom commit message.

```bash
# Ship with auto-generated commit message
/ship

# Ship with custom commit description
/ship DESC="feat: add user profile export"

# Ship bug fix
/ship DESC="fix: prevent null pointer in payment flow"
```

**What it does:**
1. **Branch Check**: If on main, creates new branch; otherwise uses current branch
2. **Commit**: Stages all changes and commits with provided or auto-generated message
3. **Push**: Pushes to remote with upstream tracking
4. **PR**: Creates pull request (or uses existing if already created)
5. **Review & Merge**: Automatically reviews and merges if ready and CI passes

**When to use:**
- You have local changes ready to ship
- Changes are straightforward and well-tested
- You want the fastest path from local edits to merged PR
- You're confident in the changes and want automated review/merge

**Safety:**
- Never force pushes
- Verifies CI passes before merging
- Creates PR for review transparency
- Follows same review criteria as `/tl review_and_merge`

---

## Command Reference (Other Agents)

| Command | Description | Example Usage |
|---------|-------------|---------------|
| `/test-health` | Analyze test suite for flaky/slow tests | `/test-health` |
| `/pe plan` | Run terraform plan with risk summary | `/pe plan DIR=./infra WORKSPACE=prod` |
| `/pe apply` | Apply terraform changes (requires approval) | `/pe apply DIR=./infra WORKSPACE=staging` |
| `/dbg` | Debug issues with scoped analysis | `/dbg "500 error on login endpoint"` |
| `/arch plan` | Create architecture integration plan | `/arch plan FEATURE="real-time notifications"` |
| `/doc` | Create or update documentation | `/doc FEATURE="user authentication flow"` |
| `/orient` | Understand PRs/issues and suggest next steps | `/orient PR=123` or `/orient ISSUE=456` |
| `/pull_main` | Checkout main branch and pull latest changes | `/pull_main` |
| `/rebase` | Rebase current branch on latest main with conflict resolution | `/rebase` |

See individual command files in `commands/` for detailed documentation.

## Hooks Overview

### Pre-Safety Check (`pre_safety_check.sh`)

Intercepts Bash tool calls before execution and blocks high-risk operations:

- Terraform apply/destroy commands
- Kubernetes apply/delete operations
- Production database commands
- AWS/Azure destructive operations
- Docker system prune

Returns JSON with `{"decision": "block"}` or `{"decision": "approve"}`.

### Post-Telemetry (`post_telemetry.sh`)

Logs all tool usage to `~/.claude/telemetry.log` for:

- Audit trails
- Usage analysis
- Performance monitoring
- Compliance tracking

Logs include timestamp, tool name, description, and exit status.

## Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed installation instructions, including:

- Prerequisites
- Global vs. project-local installation
- Manual installation steps
- Verification and testing
- Updating and uninstallation

## Testing

### Run Validation Tests

```bash
make test
```

The test suite validates:

- Directory structure
- settings.json syntax and hook references
- Hook script executability and format
- Command frontmatter and examples
- CLAUDE.md content

### Manual Testing

```bash
# Test a hook script directly
./.claude/hooks/pre_safety_check.sh "terraform apply"
./.claude/hooks/post_telemetry.sh "Bash" "test command" "0"

# Validate settings.json syntax
jq empty settings.json

# Test a command
claude /test-health
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions to common issues:

- Commands not recognized
- Hooks not triggering
- Permission errors
- Model configuration issues
- jq installation problems

## Architecture

### Directory Structure

```
.claude/
├── commands/           # Slash command definitions
│   ├── arch.md
│   ├── dbg.md
│   ├── doc.md
│   ├── jswe.md
│   ├── orient.md
│   ├── pe.md
│   ├── pull_main.md
│   ├── rebase.md
│   ├── ship.md
│   ├── swe.md
│   ├── test-health.md
│   └── tl.md
├── hooks/             # Executable safety and telemetry hooks
│   ├── pre_safety_check.sh
│   └── post_telemetry.sh
├── agents/            # Agent definitions (optional)
├── skills/            # Reusable skill modules (optional)
└── settings.json      # Hook configuration and permissions
```

### Models Used

- **Sonnet 4.5**: `sonnet` (default for most commands: /ship, /swe, /dbg, /arch, /tl, /doc, /orient)
- **Haiku 4.5**: `haiku` (for lightweight operations: /jswe)

Commands specify their model in frontmatter; defaults to Sonnet if not specified. Use `/jswe` instead of `/swe` for simple tasks to save cost and time.

## Customization

### Adding New Commands

Create a new `.md` file in `commands/`:

```markdown
---
description: Brief description of what this command does
model: sonnet
allowed-tools: Bash(make:*), Read, Grep
---

# Command Name

Instructions for the agent...

## Examples

\`\`\`
/your-command arg1 arg2
\`\`\`
```

### Modifying Safety Rules

Edit `.claude/hooks/pre_safety_check.sh` to add or remove blocked patterns:

```bash
# Add new dangerous pattern
if echo "$COMMAND" | grep -qE 'rm -rf /'; then
  block "Blocked: dangerous rm command"
fi
```

### Extending Permissions

Edit `settings.json` to add new allowed commands:

```json
{
  "permissions": {
    "allow": [
      "Bash(your-command:*)"
    ]
  }
}
```

## Contributing

### Development Workflow

1. Make changes to commands, hooks, or settings
2. Run `make test` to validate configuration
3. Test commands manually in a project
4. Update documentation if needed
5. Create a PR with changes

### Guidelines

- Keep commands focused and single-purpose
- Add examples to all command files
- Test hooks with real scenarios
- Document safety implications
- Follow existing patterns and conventions

## Documentation

### User Guides
- **[INSTALLATION.md](INSTALLATION.md)** - Detailed installation instructions
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **[PROMPTING_GUIDE.md](PROMPTING_GUIDE.md)** - How to use commands effectively
- **[BIN_SCRIPTS.md](BIN_SCRIPTS.md)** - Helper scripts in `bin/` directory

### Technical Documentation
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System architecture and component interactions
- **[docs/RISK_REGISTER.md](docs/RISK_REGISTER.md)** - Safety policies and risk assessment
- **[docs/EXECUTION.md](docs/EXECUTION.md)** - Implementation specification and as-built documentation

## License

MIT License - see LICENSE file for details.

## Support

For issues, questions, or contributions:

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) first
- Review command examples in `commands/`
- Check hook scripts in `hooks/`
- Verify settings.json configuration

---

Built with Claude Code CLI for autonomous, safe, and efficient software development workflows.
