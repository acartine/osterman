---
name: pull_main
description: Checkout main branch and pull latest changes from remote.
inputs: {}
outputs: { status: string }
dependencies: [ git ]
safety: Read-only on remote; updates local working directory.
steps:
  - Checkout main branch: git checkout main
  - Pull latest changes: git pull
tooling:
  - git checkout, git pull
---

# Pull Main Skill

## Overview
Simple utility to checkout the main branch and pull the latest changes from remote.

## Usage
```bash
git checkout main && git pull
```

## Safety
- Switches to main branch (may abandon uncommitted work on current branch)
- Pulls latest changes from remote (updates local main)
- Does not push or modify remote state

## Common Use Cases
- Syncing local main with remote before starting new work
- Getting latest changes after a PR is merged
- Resetting context to main branch
