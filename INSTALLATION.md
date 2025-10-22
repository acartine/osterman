# Installation Guide

Complete installation instructions for the Osterman Claude Configuration.

## Prerequisites

Before installing, ensure you have the following tools installed:

### Required

- **Claude Code CLI** - The Claude command-line interface
  ```bash
  # Verify installation
  claude --version
  ```

- **jq** - JSON processor (required by hooks)
  ```bash
  # macOS
  brew install jq

  # Linux (Debian/Ubuntu)
  sudo apt-get install jq

  # Linux (RHEL/CentOS)
  sudo yum install jq

  # Verify installation
  jq --version
  ```

- **git** - Version control
  ```bash
  git --version
  ```

### Optional (for specific features)

- **gh** - GitHub CLI (for `/tl` and `/swe` commands)
  ```bash
  brew install gh
  gh --version
  ```

- **terraform** - Infrastructure as code (for `/pe` commands)
  ```bash
  terraform --version
  ```

- **make** - Build automation (for testing only)
  ```bash
  make --version
  ```

## Recommended: Fork First

Before installing, we strongly recommend forking this repository to your own GitHub account. This allows you to:

- Customize the configuration for your needs
- Version control your changes
- Easily sync updates from upstream
- Contribute improvements back via pull request
- Use different branches for different configurations

To fork:
1. Go to the repository on GitHub
2. Click the "Fork" button
3. Clone your fork instead of the original repository

## Installation

Installation is simple and identical for both user-level and project-level installations.

### User-Level Installation

Install to `~/.claude` to make commands available in all projects:

```bash
# 1. Backup existing .claude directory (if it exists)
if [ -d ~/.claude ]; then
  mv ~/.claude ~/.claude.backup-$(date +%Y%m%d%H%M%S)
fi

# 2. Clone the repository (or your fork)
git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude

# 3. That's it! Verify the installation
cd ~/.claude
make test
```

### Project-Level Installation

Install to `.claude/` in your project directory. Use this when:
- Working on a team project
- Want project-specific commands
- Need to commit configuration to version control

```bash
# 1. Navigate to your project
cd /path/to/your/project

# 2. Backup existing .claude directory (if it exists)
if [ -d .claude ]; then
  mv .claude .claude.backup-$(date +%Y%m%d%H%M%S)
fi

# 3. Clone the repository (or your fork)
git clone https://github.com/YOUR_USERNAME/osterman.git .claude

# 4. Update hook paths in settings.json
# By default, hooks point to ~/.claude/hooks/ (user-level)
# For project-level hooks, update .claude/settings.json:
cd .claude
sed -i.bak 's|~/.claude/hooks/|"$CLAUDE_PROJECT_DIR"/.claude/hooks/|g' settings.json

# 5. Verify the installation
make test
```

**Important Note about Hooks:**

By default, `settings.json` references hooks at `~/.claude/hooks/` (user-level). This is intentional to allow:
- Sharing hooks across all projects
- Centralized hook management
- Avoiding hook duplication

For project-level installations, you have two options:

**Option A: Use User-Level Hooks (Recommended)**
- Keep the default `~/.claude/hooks/` paths in settings.json
- Install hooks once at user-level: `~/.claude/hooks/`
- All projects use the same hooks

**Option B: Use Project-Level Hooks**
- Update settings.json to use `$CLAUDE_PROJECT_DIR` instead of `~`
- Copy hooks to project: `cp ~/.claude/hooks/*.sh .claude/hooks/`
- Each project has its own hooks (useful for custom project rules)

### Hybrid Approach

You can combine both approaches:

1. Install globally for base configuration
2. Install project-locally to override specific settings
3. Add project-specific commands in `.claude/commands/`

Claude Code will merge global and local configurations, with local taking precedence.

## Verification

After installation, verify everything is working:

### 1. Run Validation Tests

```bash
# From the osterman repository
make test

# Or manually
./test/validate-config.sh ~/.claude
```

Expected output:
```
========================================
  Claude Config Validation
========================================
Config directory: /Users/you/.claude

✓ commands/ directory exists
✓ hooks/ directory exists
✓ settings.json is valid JSON
✓ Hook script is executable: pre_safety_check.sh
✓ Command has frontmatter: test-health.md
✓ Found 6 command file(s)

========================================
  Results
========================================
Passed: 15
Failed: 0

✓ All validations passed!
```

### 2. Test Hook Scripts

```bash
# Test pre-safety hook
~/.claude/hooks/pre_safety_check.sh "terraform apply"
# Should output: {"decision": "block", "message": "..."}

# Test post-telemetry hook
~/.claude/hooks/post_telemetry.sh "Bash" "test command" "0"
# Should log to ~/.claude/telemetry.log
```

### 3. Test a Command

```bash
# Test the test-health command
claude /test-health

# If you get "Unknown command", ensure:
# 1. Commands are in ~/.claude/commands/ or .claude/commands/
# 2. Files have .md extension
# 3. Files have proper frontmatter
```

### 4. Check Telemetry Log

```bash
# View recent telemetry entries
tail -f ~/.claude/telemetry.log

# Should show entries like:
# 2025-10-21T14:30:45Z | Bash | Run test suite | exit=0
```

## Customization

Since the configuration is now a git repository, you can customize it like any other codebase.

### Making Changes

```bash
# Navigate to your .claude directory
cd ~/.claude  # or cd /path/to/project/.claude

# Create a branch for your changes (optional but recommended)
git checkout -b my-customizations

# Edit files as needed
vim settings.json
vim commands/my-command.md

# Commit your changes
git add .
git commit -m "Add custom settings and commands"

# Push to your fork
git push origin my-customizations
```

### Customizing Settings

Edit `settings.json` directly:

```bash
cd ~/.claude
vim settings.json  # or use your preferred editor
```

Example customizations:
```json
{
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...]
  },
  "env": {
    "CLAUDE_TELEMETRY": "1"
  },
  "permissions": {
    "allow": [...],
    "ask": [...]
  }
}
```

### Adding Custom Commands

Create new command files:

```bash
cd ~/.claude/commands
cat > my-command.md <<'EOF'
---
description: My custom command
model: claude-sonnet-4-5-20250929
---

# My Command

Instructions for Claude...
EOF

# Commit the new command
git add my-command.md
git commit -m "Add my-command"
```

### Using Branches for Different Configurations

You can use git branches to maintain different configurations:

```bash
cd ~/.claude

# Create a branch for work projects
git checkout -b work-config
# Edit settings, add work-specific commands
git commit -am "Work configuration"

# Create a branch for personal projects
git checkout -b personal-config
# Edit settings, add personal commands
git commit -am "Personal configuration"

# Switch between configurations
git checkout work-config    # Use work settings
git checkout personal-config # Use personal settings
```

## Updating

Updating is simple with git pull.

### Basic Update

```bash
# Navigate to your .claude directory
cd ~/.claude  # or cd /path/to/project/.claude

# Pull latest changes from upstream
git pull
```

### Update with Customizations

If you've made local customizations:

```bash
cd ~/.claude

# Stash your local changes
git stash

# Pull latest updates
git pull

# Re-apply your changes
git stash pop

# If there are conflicts, resolve them manually
# Then commit the merged result
git add .
git commit -m "Merge updates with local customizations"
```

### Sync with Upstream (if using a fork)

```bash
cd ~/.claude

# Add upstream remote (only needed once)
git remote add upstream https://github.com/ORIGINAL_OWNER/osterman.git

# Fetch upstream changes
git fetch upstream

# Merge upstream changes into your fork
git merge upstream/main

# Push to your fork
git push origin main
```

### Using Different Versions

You can check out specific versions or branches:

```bash
cd ~/.claude

# Check out a specific version tag
git checkout v1.0.0

# Check out a specific branch
git checkout experimental-features

# Return to main branch
git checkout main
```

## Uninstallation

Uninstallation is straightforward since the configuration is just a directory.

### Remove Installation

```bash
# Remove global installation
rm -rf ~/.claude

# OR remove project-local installation
rm -rf /path/to/project/.claude
```

### Restore from Backup

If you created a backup during installation:

```bash
# List available backups
ls -la ~ | grep claude.backup

# Restore a backup
mv ~/.claude.backup-20251021143045 ~/.claude

# Or restore the most recent backup
mv ~/.claude.backup ~/.claude
```

### Selective Removal

Remove only telemetry logs:

```bash
rm ~/.claude/telemetry.log
```

## Troubleshooting

### Installation Issues

**Git clone fails:**
```bash
# Ensure you have git installed
git --version

# Verify the repository URL is correct
# If using a fork, replace with your username
git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude
```

**jq not found:**
```bash
# Install jq first
brew install jq  # macOS
sudo apt-get install jq  # Linux
```

**Permission denied on hooks:**
```bash
# Hook scripts should be executable by default
# If not, make them executable:
chmod +x ~/.claude/hooks/*.sh
```

**Validation fails:**
```bash
# Navigate to .claude directory
cd ~/.claude

# Run tests
make test

# Fix common issues:
# - Invalid JSON: validate with `jq empty settings.json`
# - Hook permissions: run chmod +x ~/.claude/hooks/*.sh
```

### Update Issues

**Merge conflicts:**
```bash
# When conflicts occur during git pull
cd ~/.claude

# View conflicted files
git status

# Resolve conflicts manually, then:
git add .
git commit -m "Resolve merge conflicts"
```

**Lost customizations:**
```bash
# Recover from git reflog
cd ~/.claude
git reflog
git checkout HEAD@{1}  # or appropriate commit

# Or restore from stash
git stash list
git stash apply stash@{0}
```

### Need Help?

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions to common issues.

## Next Steps

After installation:

1. Read [README.md](README.md) for feature overview
2. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
3. Review command examples in `commands/` directory
4. Customize settings for your workflow
5. Try the commands in a test project

## Additional Resources

- **Claude Code Documentation**: Official Claude Code CLI docs
- **Command Reference**: See README.md for all available commands
- **Hook Development**: See hooks/ directory for implementation examples
- **Agent Specifications**: Review agents/ directory for agent definitions

---

Installation complete! Start using commands with `claude /command-name`.
