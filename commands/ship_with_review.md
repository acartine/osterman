---
description: Ship changes with automated third-party code review loop - from issue to merged PR
argument-hint: <issue-number>
allowed-tools: Bash(git:*), Bash(gh:*), Bash(codex:*), Bash(make:*), Bash(npm:*), Bash(pytest:*), Read, Grep, Glob, Write, Edit
model: opus
---

# Ship With Review Command

End-to-end workflow from GitHub issue to merged PR with automated third-party review loop.

## Arguments
User provided: $ARGUMENTS

Expected format: `<issue-number>`

## Instructions

1. Parse the issue number from arguments
2. Auto-detect repository from git remote: `git remote get-url origin`
3. Execute the `ship_with_review` skill with `issue=<number>` and `repo=<org/repo>`

Follow the workflow defined in `skills/ship_with_review.md`.
