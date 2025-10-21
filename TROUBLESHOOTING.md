# Troubleshooting Guide

Solutions to common issues with the Osterman Claude Configuration.

## Common Issues

### Installation Issues

**Symptom:** Git clone fails or installation doesn't complete

**Solutions:**

1. **Verify git is installed:**
   ```bash
   git --version
   ```

2. **Check repository URL:**
   ```bash
   # Make sure you're using the correct URL
   # If forked, use your username
   git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude
   ```

3. **Check directory doesn't already exist:**
   ```bash
   # If .claude already exists, back it up first
   mv ~/.claude ~/.claude.backup-$(date +%Y%m%d%H%M%S)
   git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude
   ```

4. **Verify installation:**
   ```bash
   ls -la ~/.claude/
   # Should see: commands/, hooks/, agents/, skills/, settings.json, etc.
   ```

### Commands Not Recognized

**Symptom:** Claude responds with "Unknown slash command" or doesn't recognize `/command-name`

**Solutions:**

1. **Verify command files exist:**
   ```bash
   ls ~/.claude/commands/
   # OR for project-local
   ls .claude/commands/
   ```
   You should see `.md` files for each command.

2. **Check command frontmatter:**
   ```bash
   head -n 10 ~/.claude/commands/test-health.md
   ```
   Should start with:
   ```markdown
   ---
   description: ...
   ---
   ```

3. **Verify Claude Code version:**
   ```bash
   claude --version
   ```
   Ensure you have a recent version that supports slash commands.

4. **Check file permissions:**
   ```bash
   ls -la ~/.claude/commands/
   ```
   Files should be readable (644 permissions minimum).

5. **Try without slash:**
   Instead of `/test-health`, type the full command:
   ```
   Run the test-health command
   ```

### Hooks Not Triggering

**Symptom:** Safety checks don't block dangerous commands or telemetry isn't logging

**Solutions:**

1. **Verify settings.json configuration:**
   ```bash
   jq '.hooks' ~/.claude/settings.json
   ```
   Should show PreToolUse and PostToolUse hook definitions.

2. **Check hook scripts are executable:**
   ```bash
   ls -la ~/.claude/hooks/
   ```
   Scripts should have execute permission (755 or 744):
   ```bash
   chmod +x ~/.claude/hooks/*.sh
   ```

3. **Test hooks directly:**
   ```bash
   # Test pre-safety hook
   ~/.claude/hooks/pre_safety_check.sh "terraform apply"
   # Expected: {"decision": "block", ...}

   # Test telemetry hook
   ~/.claude/hooks/post_telemetry.sh "Bash" "test" "0"
   # Check log: tail ~/.claude/telemetry.log
   ```

4. **Verify hook paths in settings.json:**
   ```bash
   jq '.hooks.PreToolUse[].hooks[].command' ~/.claude/settings.json
   ```
   Paths should reference `.claude/hooks/*.sh`

5. **Check for settings.local.json conflicts:**
   If using project-local config, ensure `.claude/settings.local.json` includes hooks:
   ```bash
   jq '.hooks' .claude/settings.local.json
   ```

### Permission Errors

**Symptom:** "Permission denied" or "Command not allowed" errors

**Solutions:**

1. **Check permissions in settings.json:**
   ```bash
   jq '.permissions.allow' ~/.claude/settings.json
   ```
   Ensure the command you're trying to use is in the allow list.

2. **Add missing command to allow list:**
   Edit `settings.json`:
   ```json
   {
     "permissions": {
       "allow": [
         "Bash(your-command:*)"
       ]
     }
   }
   ```

3. **Check for blocked patterns:**
   Some commands may be intentionally blocked by the pre-safety hook:
   ```bash
   grep "block" ~/.claude/hooks/pre_safety_check.sh
   ```

4. **Verify Write/Edit permissions:**
   By default, Write and Edit require approval:
   ```json
   {
     "permissions": {
       "ask": ["Write", "Edit"]
     }
   }
   ```
   Change to `"allow"` if you want automatic approval (not recommended).

### Model Not Found Errors

**Symptom:** "Model not found" or "Invalid model ID" errors

**Solutions:**

1. **Check model IDs in command frontmatter:**
   ```bash
   grep "^model:" ~/.claude/commands/*.md
   ```

2. **Verify model IDs are correct:**
   - Sonnet 4.5: `claude-sonnet-4-5-20250929`
   - Haiku 4.5: `claude-haiku-4-5-20251001`

3. **Update outdated model IDs:**
   If you see older model IDs (claude-3-5-sonnet-20241022, etc.), update them:
   ```bash
   # Edit each command file
   vim ~/.claude/commands/test-health.md
   # Change model: line to correct ID
   ```

4. **Remove model line to use default:**
   If uncertain, remove the `model:` line from frontmatter and Claude will use the default.

### jq Not Installed

**Symptom:** Hooks fail with "jq: command not found"

**Solutions:**

1. **Install jq:**
   ```bash
   # macOS
   brew install jq

   # Linux (Debian/Ubuntu)
   sudo apt-get install jq

   # Linux (RHEL/CentOS)
   sudo yum install jq

   # Linux (Arch)
   sudo pacman -S jq
   ```

2. **Verify installation:**
   ```bash
   jq --version
   # Should output: jq-1.6 or similar
   ```

3. **Test with hooks:**
   ```bash
   ~/.claude/hooks/pre_safety_check.sh "echo test"
   # Should output JSON, not an error
   ```

### Telemetry Not Logging

**Symptom:** No entries in telemetry.log or file doesn't exist

**Solutions:**

1. **Verify telemetry is enabled:**
   ```bash
   jq '.env.CLAUDE_TELEMETRY' ~/.claude/settings.json
   # Should output: "1"
   ```

2. **Check log file permissions:**
   ```bash
   ls -la ~/.claude/telemetry.log
   ```
   Should be writable. If it doesn't exist, create it:
   ```bash
   touch ~/.claude/telemetry.log
   ```

3. **Test telemetry hook manually:**
   ```bash
   ~/.claude/hooks/post_telemetry.sh "Bash" "test command" "0"
   tail -n 1 ~/.claude/telemetry.log
   # Should show the test entry
   ```

4. **Check hook is configured:**
   ```bash
   jq '.hooks.PostToolUse' ~/.claude/settings.json
   ```
   Should include post_telemetry.sh

### Hook Blocking When It Shouldn't

**Symptom:** Safe commands are being blocked by pre-safety hook

**Solutions:**

1. **Review blocked patterns:**
   ```bash
   cat ~/.claude/hooks/pre_safety_check.sh | grep -A 2 "block"
   ```

2. **Adjust blocking rules:**
   Edit the hook script to refine patterns:
   ```bash
   vim ~/.claude/hooks/pre_safety_check.sh
   ```

3. **Add exceptions:**
   Modify the hook to allow specific patterns:
   ```bash
   # Example: allow terraform plan but block apply
   if echo "$COMMAND" | grep -qE 'terraform (apply|destroy)'; then
     block "Blocked: terraform apply/destroy"
   fi
   # terraform plan will pass through
   ```

4. **Temporarily disable hook:**
   Comment out the hook in settings.json (not recommended for production):
   ```json
   {
     "hooks": {
       "PreToolUse": []
     }
   }
   ```

### Settings.json Syntax Errors

**Symptom:** Configuration not loading or syntax error messages

**Solutions:**

1. **Validate JSON syntax:**
   ```bash
   jq empty ~/.claude/settings.json
   ```
   If there's an error, it will show the line number.

2. **Common JSON errors:**
   - Missing comma between array/object elements
   - Trailing comma after last element
   - Unescaped quotes in strings
   - Missing closing bracket/brace

3. **Use a JSON validator:**
   ```bash
   # Format and validate
   jq '.' ~/.claude/settings.json > /tmp/settings.json
   mv /tmp/settings.json ~/.claude/settings.json
   ```

4. **Compare with reference:**
   Check the original settings.json from the repository for correct format.

### Commands Not Finding Files

**Symptom:** Commands can't find project files or directories

**Solutions:**

1. **Check working directory:**
   Commands run from the project root where you invoked `claude`.

2. **Use absolute paths:**
   ```bash
   claude /pe plan DIR=/full/path/to/infra WORKSPACE=staging
   ```

3. **Verify environment variables:**
   The `$CLAUDE_PROJECT_DIR` variable should point to project root:
   ```bash
   echo $CLAUDE_PROJECT_DIR
   ```

4. **Check command implementation:**
   Some commands may need paths relative to project root:
   ```bash
   claude /pe plan DIR=./infra  # Relative path
   ```

## Debugging Steps

### Enable Verbose Logging

Add debug output to hooks:

```bash
# Edit hook script
vim ~/.claude/hooks/pre_safety_check.sh

# Add near the top (after shebang)
set -x  # Enable bash debug mode
```

### Test Configuration Thoroughly

```bash
# Run full validation
make test

# Test individual components
./test/validate-config.sh ~/.claude

# Check each command manually
for cmd in ~/.claude/commands/*.md; do
  echo "Checking $(basename $cmd)..."
  head -n 10 "$cmd"
done
```

### Isolate the Problem

1. **Test with minimal config:**
   - Create a new `.claude/` with just one command
   - Test if that works
   - Add components back one at a time

2. **Check Claude Code logs:**
   ```bash
   # Location varies by platform
   # Look for error messages or stack traces
   ```

3. **Compare working vs. broken:**
   - If it works globally but not locally (or vice versa)
   - Compare settings.json files
   - Check for path differences

### Verify Installation

```bash
# Check all required files exist
ls -R ~/.claude/

# Should see:
# commands/ with .md files
# hooks/ with .sh files
# settings.json
# CLAUDE.md (optional)
```

## Getting Help

### Information to Gather

When reporting an issue, include:

1. **Claude Code version:**
   ```bash
   claude --version
   ```

2. **Installation type:**
   - Global (~/.claude)
   - Project-local (.claude/)
   - Hybrid

3. **Validation output:**
   ```bash
   make test
   ```

4. **Command that failed:**
   - Exact command you ran
   - Error message received
   - Expected vs. actual behavior

5. **Hook test results:**
   ```bash
   ~/.claude/hooks/pre_safety_check.sh "test command"
   ~/.claude/hooks/post_telemetry.sh "Bash" "test" "0"
   ```

6. **Settings.json (sanitized):**
   ```bash
   jq '.' ~/.claude/settings.json
   # Remove any sensitive information
   ```

### Self-Service Diagnostics

Run this diagnostic script:

```bash
#!/bin/bash
echo "=== Claude Config Diagnostics ==="
echo ""
echo "Claude Code Version:"
claude --version
echo ""
echo "Installation Check:"
ls -la ~/.claude/ 2>/dev/null || echo "Global installation not found"
ls -la .claude/ 2>/dev/null || echo "Local installation not found"
echo ""
echo "Settings Validation:"
jq empty ~/.claude/settings.json && echo "✓ Valid JSON" || echo "✗ Invalid JSON"
echo ""
echo "Hook Executability:"
ls -la ~/.claude/hooks/*.sh
echo ""
echo "Command Count:"
ls -1 ~/.claude/commands/*.md 2>/dev/null | wc -l
echo ""
echo "Telemetry Status:"
tail -n 5 ~/.claude/telemetry.log 2>/dev/null || echo "No telemetry log found"
```

### Community Resources

- Check README.md for basic usage
- Review INSTALLATION.md for setup steps
- Read command files in `commands/` for examples
- Inspect hook scripts in `hooks/` for implementation details

### Reset to Defaults

If all else fails, reinstall from scratch:

```bash
# Remove current installation
rm -rf ~/.claude

# Reinstall fresh
git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude

# Verify
cd ~/.claude
make test
```

### Update Issues

**Symptom:** Git pull fails or creates conflicts

**Solutions:**

1. **View current status:**
   ```bash
   cd ~/.claude
   git status
   ```

2. **Stash local changes before pulling:**
   ```bash
   git stash
   git pull
   git stash pop
   ```

3. **Resolve merge conflicts:**
   ```bash
   # View conflicted files
   git status

   # Edit files to resolve conflicts
   # Then add and commit
   git add .
   git commit -m "Resolve merge conflicts"
   ```

4. **Force update (discards local changes):**
   ```bash
   cd ~/.claude
   git fetch origin
   git reset --hard origin/main
   # WARNING: This will discard all local changes
   ```

5. **Sync fork with upstream:**
   ```bash
   cd ~/.claude
   git remote add upstream https://github.com/ORIGINAL_OWNER/osterman.git
   git fetch upstream
   git merge upstream/main
   ```

## Prevention Tips

### Keep Configuration Simple

- Start with default settings
- Add customizations incrementally
- Test after each change
- Document modifications

### Regular Validation

```bash
# Run periodically
make test

# Before committing changes
git add .claude/
make test && git commit
```

### Version Control

```bash
# Track .claude config in git
git add .claude/

# Exclude logs
echo ".claude/telemetry.log" >> .gitignore

# Commit with validation
make test && git commit -m "Update Claude config"
```

### Stay Updated

```bash
# Navigate to your .claude directory
cd ~/.claude

# Pull updates regularly
git pull

# Review changes after updating
git log -5 --oneline
git diff HEAD~1 HEAD
```

---

If you've tried these solutions and still have issues, gather the diagnostic information above and seek help from the community or project maintainers.
