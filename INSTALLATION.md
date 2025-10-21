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

- **make** - Build automation (recommended for easy installation)
  ```bash
  make --version
  ```

## Installation Options

Choose between global installation (recommended for personal use) or project-local installation (recommended for team projects).

### Option 1: Global Installation

Install to `~/.claude` to make commands available in all projects.

#### Using Make (Recommended)

```bash
# Clone or download the repository
git clone <repository-url> osterman
cd osterman

# Run installation
make install
```

This will:
1. Backup existing `~/.claude` to `~/.claude.backup`
2. Copy all configuration files to `~/.claude`
3. Set executable permissions on hook scripts
4. Display installation summary

#### Manual Installation

If you prefer not to use make or need more control:

```bash
# Backup existing configuration
if [ -d ~/.claude ]; then
  cp -r ~/.claude ~/.claude.backup-$(date +%Y%m%d%H%M%S)
fi

# Create directory
mkdir -p ~/.claude

# Copy configuration files
cp -r commands ~/.claude/
cp -r hooks ~/.claude/
cp -r agents ~/.claude/
cp -r skills ~/.claude/
cp settings.json ~/.claude/
cp CLAUDE.md ~/.claude/

# Make hook scripts executable
chmod +x ~/.claude/hooks/*.sh

# Verify installation
ls -la ~/.claude
```

### Option 2: Project-Local Installation

Install to `.claude/` in your project directory. Use this when:
- Working on a team project
- Want project-specific commands
- Need to commit configuration to version control

#### Using Make (Recommended)

```bash
# From the osterman repository
make install-local
```

This will:
1. Create `.claude/` directory in current project
2. Copy all configuration files
3. Create `settings.local.json` (automatically loaded by Claude Code)
4. Set executable permissions on hooks

#### Manual Installation

```bash
# Create .claude directory
mkdir -p .claude

# Copy configuration files
cp -r commands .claude/
cp -r hooks .claude/
cp -r agents .claude/
cp -r skills .claude/

# Copy settings.json as settings.local.json for project-local config
cp settings.json .claude/settings.local.json

# Make hook scripts executable
chmod +x .claude/hooks/*.sh

# Add to .gitignore if desired (optional)
echo ".claude/telemetry.log" >> .gitignore
```

### Option 3: Hybrid Approach

You can combine both approaches:

1. Install globally for base configuration
2. Override specific settings in project `.claude/settings.local.json`
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

## Configuration

### Customizing Settings

Edit `~/.claude/settings.json` or `.claude/settings.local.json`:

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

Create new command files in `~/.claude/commands/`:

```bash
# Create new command
cat > ~/.claude/commands/my-command.md <<'EOF'
---
description: My custom command
model: claude-sonnet-4-5-20250929
---

# My Command

Instructions for Claude...
EOF
```

### Disabling Hooks

To temporarily disable a hook, edit `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [],  // Disable pre-hooks
    "PostToolUse": []  // Disable post-hooks
  }
}
```

## Updating

### Update Global Installation

```bash
# Pull latest changes
cd osterman
git pull

# Reinstall (backs up existing config)
make install

# Or manually copy specific files
cp commands/*.md ~/.claude/commands/
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

### Update Project-Local Installation

```bash
# Pull latest changes
cd osterman
git pull

# Reinstall to project
make install-local

# Or manually update
cp commands/*.md .claude/commands/
cp hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

### Selective Updates

Update only specific components:

```bash
# Update only commands
cp commands/*.md ~/.claude/commands/

# Update only hooks
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# Update only settings
cp settings.json ~/.claude/settings.json
```

## Uninstallation

### Remove Global Installation

Using make:

```bash
make uninstall
```

This will:
1. Prompt for confirmation
2. Remove `~/.claude` directory
3. Offer to restore backup from `~/.claude.backup`

Manual removal:

```bash
# Remove configuration
rm -rf ~/.claude

# Optionally restore backup
mv ~/.claude.backup ~/.claude
```

### Remove Project-Local Installation

```bash
# Remove .claude directory
rm -rf .claude
```

### Clean Telemetry Logs

```bash
# Remove telemetry log
rm ~/.claude/telemetry.log

# Or clear while keeping file
> ~/.claude/telemetry.log
```

## Troubleshooting

### Installation Fails

**jq not found:**
```bash
# Install jq first
brew install jq  # macOS
sudo apt-get install jq  # Linux
```

**Permission denied on hooks:**
```bash
# Make scripts executable
chmod +x ~/.claude/hooks/*.sh
```

**Validation fails:**
```bash
# Check what failed
make test

# Fix common issues:
# - Invalid JSON: validate with `jq empty settings.json`
# - Missing files: ensure all directories copied
# - Hook permissions: run chmod +x
```

### Commands Not Working

**Command not recognized:**
1. Check command exists: `ls ~/.claude/commands/`
2. Verify frontmatter: `head -n 5 ~/.claude/commands/test-health.md`
3. Check Claude Code version: `claude --version`

**Hooks not triggering:**
1. Verify hooks in settings.json
2. Check hook script is executable: `ls -la ~/.claude/hooks/`
3. Test hook directly: `~/.claude/hooks/pre_safety_check.sh "test"`

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
