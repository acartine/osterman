# Osterman Claude Configuration

Production-ready Claude Code configuration for autonomous software development workflows.

## What is this?

The `osterman` .claude configuration provides specialized slash commands, safety hooks, and autonomous agent workflows for professional software development. It implements a secure, efficient approach to infrastructure management, code implementation, PR review, and debugging using Claude Code CLI.

## Why is it called `osterman`?
Before he was Dr. Manhattan, he was Jon Osterman.  We hope someday to be Dr. Manhattan.

## Features

### Slash Commands

Eight specialized commands for common development workflows:

- **`/test-health`** - Generate test health reports with flaky and slow test analysis
- **`/pe`** - Production Engineering workflows with safety guardrails for infrastructure changes
- **`/tl`** - Team Lead workflows for issue triage and ticket creation
- **`/sswe`** - Staff Software Engineering for complex implementations *(obsolete - now uses Opus like /swe)*
- **`/swe`** - Software Engineering implementation with branch workflow and DRAFT PRs (Opus-powered)
- **`/jswe`** - Junior Software Engineering for simple tasks *(obsolete - now uses Opus like /swe)*
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
# Team Lead: Create a bug report
claude /tl ticket TYPE='bug' DESC='Login fails with OAuth providers'

# Team Lead: Triage open issues
claude /tl triage

# Staff SWE: Complex implementation (Opus - highest capability)
claude /sswe ticket 789
claude /sswe impl TASK="microservices-migration" SPEC="Split monolith into auth and data services"

# Software Engineer: Implement from GitHub issue (Sonnet - for standard tasks)
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

**Purpose**: Autonomous issue triage and ticket creation
**Model**: Opus 4.5
**Autonomy**: Full

**Operations:**

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

### `/sswe` - Staff Software Engineering Agent

**Purpose**: Complex, high-impact feature implementation requiring highest capability
**Model**: Opus 4.1 (highest capability model)
**Autonomy**: Full - implements, tests, creates PRs with deep analysis

**Operations:**

#### `impl` - Complex Feature Implementation
Implements complex features requiring architectural decisions and deep analysis.

```bash
# Complex architectural change
/sswe impl TASK="distributed-cache-layer" SPEC=https://github.com/acme/specs/issues/142

# Microservices migration
/sswe impl TASK="microservices-split" SPEC="Split monolithic auth service into user, session, and permission microservices"

# Complex integration with external system
/sswe impl TASK="salesforce-sync" SPEC="Implement bi-directional sync with Salesforce including conflict resolution"

# Performance optimization requiring analysis
/sswe impl TASK="optimize-search-queries" SPEC="Profile and optimize product search queries, implement caching layer"

# Security-sensitive implementation
/sswe impl TASK="implement-encryption-at-rest" SPEC="Add encryption at rest for all PII data using AWS KMS"
```

**What it does:**
- Same 8-step workflow as `/swe` but with Opus model for maximum capability
- Deep architectural analysis and design consideration
- Comprehensive edge case and error scenario analysis
- Thorough security and performance implications review
- Creates highly maintainable, extensible solutions

#### `ticket` - Complex GitHub Issue Implementation
Implements complex features based on GitHub issues requiring highest capability.

```bash
# Work on complex GitHub issue #789
/sswe ticket 789

# Complex architectural issue
/sswe ticket 256
```

**When to use SSWE:**
- Complex features with multiple integration points
- Architectural changes or refactoring
- Unclear requirements needing deep analysis
- Security-sensitive implementations
- Performance optimization requiring profiling
- Changes affecting multiple systems or services
- High business impact or risk features
- Complex state management or data flows
- Features that will set patterns for future development

---

### `/swe` - Software Engineering Agent

**Purpose**: Standard feature implementation with full workflow
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
- Standard features with moderate complexity
- Typical development tasks
- Features with clear specifications but needing careful implementation
- Moderate refactoring or enhancement work
- Features requiring standard integration patterns
- When requirements are mostly clear but implementation needs thought

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

**When to escalate to SWE or SSWE:**
- Escalate to SWE for:
  - Moderate complexity beyond simple fixes
  - Need for design decisions
  - Multiple file changes with dependencies
  - Features requiring careful planning
- Escalate to SSWE for:
  - Unclear or conflicting requirements
  - Major architectural decisions
  - Complex integration points or dependencies
  - Security-sensitive changes
  - Changes affecting multiple systems
  - High business impact features

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
│   ├── sswe.md
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

- **Opus 4.5**: `opus` (all SWE agents: /swe, /sswe, /jswe)
- **Sonnet 4.5**: `sonnet` (other commands: /dbg, /arch, /tl, /doc, /orient)

Commands specify their model in frontmatter; defaults to Sonnet if not specified.

> **Note**: The `/jswe` and `/sswe` agents are currently obsolete since all SWE agents now use the Opus model. They are being retained in case model costs diverge in the future and we want to assign them to different models for cost optimization.

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
