# Osterman Claude Configuration

Production-ready Claude Code configuration for autonomous software development workflows.

## What is this?

The `osterman` .claude configuration provides specialized slash commands, safety hooks, and autonomous agent workflows for professional software development. It implements a secure, efficient approach to infrastructure management, code implementation, PR review, and debugging using Claude Code CLI.

## Why is it called `osterman`?
Before he was Dr. Manhattan, he was Jon Osterman.  We hope someday to be Dr. Manhattan.

## Features

### Slash Commands

Six specialized commands for common development workflows:

- **`/test-health`** - Generate test health reports with flaky and slow test analysis
- **`/pe`** - Production Engineering workflows with safety guardrails for infrastructure changes
- **`/tl`** - Team Lead workflows for PR review, issue triage, and merge management
- **`/swe`** - Software Engineering implementation with branch workflow and DRAFT PRs
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
# From any project with .claude config
claude /test-health

# Production Engineering terraform plan
claude /pe plan DIR=./infra WORKSPACE=staging

# Create a PR from current branch
claude /swe impl TASK="add-feature" SPEC="Add user authentication"
```

### Updating

```bash
# Navigate to your .claude directory
cd ~/.claude  # or cd /path/to/project/.claude

# Pull latest changes
git pull
```

## Command Reference

| Command | Description | Example Usage |
|---------|-------------|---------------|
| `/test-health` | Analyze test suite for flaky/slow tests | `/test-health` |
| `/pe plan` | Run terraform plan with risk summary | `/pe plan DIR=./infra WORKSPACE=prod` |
| `/pe apply` | Apply terraform changes (requires approval) | `/pe apply DIR=./infra WORKSPACE=staging` |
| `/tl review` | Review and merge pull requests | `/tl review REPO=org/repo PR=123` |
| `/tl triage` | Triage issues and map dependencies | `/tl triage REPO=org/repo` |
| `/swe impl` | Implement feature with branch workflow | `/swe impl TASK="feature-x" SPEC="description"` |
| `/dbg` | Debug issues with scoped analysis | `/dbg "500 error on login endpoint"` |
| `/arch plan` | Create architecture integration plan | `/arch plan FEATURE="real-time notifications"` |

See individual command files in `commands/` for detailed documentation and examples.

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
│   ├── pe.md
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

- **Sonnet 4.5**: `claude-sonnet-4-5-20250929` (default for most commands)
- **Haiku 4.5**: `claude-haiku-4-5-20251001` (for lightweight operations)

Commands specify their model in frontmatter; defaults to Sonnet if not specified.

## Customization

### Adding New Commands

Create a new `.md` file in `commands/`:

```markdown
---
description: Brief description of what this command does
model: claude-sonnet-4-5-20250929
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

## Specification

See [EXECUTION.md](EXECUTION.md) for the original implementation specification and as-built documentation.

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
