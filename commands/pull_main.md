---
description: Checkout main branch and pull latest changes
allowed-tools: Bash(git:*)
---

# Pull Main

Checkout the main branch and pull the latest changes from remote.

## Instructions
1. Execute: `git checkout main && git pull`
2. Report status (already on main, updated files, conflicts, etc.)

See `skills/pull_main.md` for details.

## Examples

**Basic usage:**
```
/pull_main
```

**Common scenarios:**
```
# Before starting new work
/pull_main

# After a PR is merged to sync local main
/pull_main

# Reset to main branch
/pull_main
```

## Safety Notes
- Will switch away from current branch (may lose uncommitted work)
- Use `git stash` first if you have uncommitted changes you want to preserve
