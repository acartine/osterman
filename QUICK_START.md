# Quick Start: Fix Osterman Configuration

This is your **immediate action guide**. Follow these steps to fix the broken configuration.

## TL;DR - What's Broken?

1. **Slash commands don't exist** - Need to create `commands/` directory with `.md` files
2. **Hooks aren't executable** - Need to create shell scripts in `hooks/`
3. **Settings incomplete** - Need to create `settings.json` with hook configuration

## 5-Minute Quick Fix

If you just want to see it work, run these commands:

```bash
cd /Users/cartine/osterman

# 1. Create a simple slash command
mkdir -p commands
cat > commands/test.md << 'EOF'
---
description: Test slash command
---
You are a test command. User said: $ARGUMENTS

Respond with: "Test command received your message!"
EOF

# 2. Create a simple safety hook
cat > hooks/test_hook.sh << 'EOF'
#!/usr/bin/env bash
INPUT=$(cat)
echo '{"continue": true}'
EOF
chmod +x hooks/test_hook.sh

# 3. Test the hook
echo '{"tool_name":"Bash"}' | hooks/test_hook.sh

# 4. Create minimal settings
cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": ["Read", "Bash(git:*)"]
  }
}
EOF
```

Now open Claude Code and type `/test hello` - it should work!

## Complete Fix (2-3 Hours)

Follow the **IMPLEMENTATION_PLAN.md** document, specifically:

### Step 1: Create All Slash Commands (1 hour)

```bash
cd /Users/cartine/osterman
mkdir -p commands

# Copy these from IMPLEMENTATION_PLAN.md Step 1.1:
# - commands/pe-plan.md
# - commands/pe-apply.md
# - commands/tl-review.md
# - commands/tl-triage.md
# - commands/swe-impl.md
# - commands/test-health.md
# - commands/dbg.md
# - commands/arch-plan.md
```

The IMPLEMENTATION_PLAN has the complete code for each file - just copy-paste!

### Step 2: Create Executable Hooks (30 minutes)

```bash
# Copy these from IMPLEMENTATION_PLAN.md Step 1.2:
# - hooks/pre_safety_check.sh
# - hooks/post_telemetry.sh

# Make executable
chmod +x hooks/*.sh

# Test them
echo '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | \
  hooks/pre_safety_check.sh | jq
```

### Step 3: Create Settings Configuration (30 minutes)

```bash
# Copy from IMPLEMENTATION_PLAN.md Step 1.3:
# - settings.json.example
# - settings.local.json.example
```

### Step 4: Test Everything (30 minutes)

```bash
# Run the test script from IMPLEMENTATION_PLAN.md
./test_phase1.sh
```

## What to Read First

1. **START HERE**: `FIX_SUMMARY.md` (5 minutes) - Understand what's broken
2. **THEN**: `IMPLEMENTATION_PLAN.md` Phase 1 (30 minutes) - Get the code
3. **FINALLY**: `SPECIFICATION.md` (20 minutes) - Understand why

## Installation After Fixing

Once you've completed the fixes above:

```bash
# For global use
cp -r commands ~/.claude/
cp -r hooks ~/.claude/
chmod +x ~/.claude/hooks/*.sh
cp settings.json.example ~/.claude/settings.json

# Test
claude
# Type: /help
# Should show your commands!
```

## Troubleshooting

### "Command not found"
- Check files are in `commands/` (not `hooks/command_router.md`)
- Verify file names: `pe-plan.md` → `/pe-plan`
- Restart Claude Code

### "Hook not blocking terraform apply"
- Check hook is executable: `ls -la hooks/*.sh`
- Test directly: `echo '{...}' | hooks/pre_safety_check.sh`
- Verify jq is installed: `brew install jq`

### "Permission denied"
- Make hooks executable: `chmod +x hooks/*.sh`
- Check settings.json exists and is valid JSON

## Files You'll Create

In Phase 1 you'll create:
- `commands/pe-plan.md` (and 7 more)
- `hooks/pre_safety_check.sh`
- `hooks/post_telemetry.sh`
- `settings.json.example`
- `settings.local.json.example`

## Success Check

You're done when:
- [ ] `/help` shows your custom commands
- [ ] `/pe-plan --help` works
- [ ] Running "terraform apply" is blocked
- [ ] Running "terraform plan" works and is logged
- [ ] All tests in test_phase1.sh pass

## Getting Help

If you get stuck:
- Check **FIX_SUMMARY.md** for common issues
- Read **SPECIFICATION.md** for detailed explanations
- Follow **IMPLEMENTATION_PLAN.md** step-by-step
- Review **ARCHITECTURE.md** for how it all fits together

## Time Estimates

- Quick test (minimal): 5 minutes
- Phase 1 (working): 2-3 hours
- Phase 2 (documented): +2 hours
- Phase 3 (polished): +2 hours
- **Total for production-ready**: 6-7 hours

## Next Steps

1. ✅ Read this file (you're here!)
2. ⏳ Read FIX_SUMMARY.md
3. ⏳ Follow IMPLEMENTATION_PLAN.md Phase 1
4. ⏳ Test with test_phase1.sh
5. ⏳ Install to ~/.claude
6. ⏳ Use in real projects!

---

**Remember**: The concept is sound, the implementation just needs to match Claude Code's architecture. You're not redesigning - just correcting the format!
