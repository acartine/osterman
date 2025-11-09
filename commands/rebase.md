---
description: Rebase current branch on latest main with conflict resolution
allowed-tools: Bash(git:*)
model: sonnet
---

# Rebase Command

Rebase the current work branch on the latest main by:
1. Storing current branch name
2. Checking out main
3. Pulling latest changes
4. Returning to work branch
5. Rebasing on main
6. Resolving conflicts automatically (with transparency)
7. Force pushing to remote

## Task
Automate the rebase workflow with intelligent conflict resolution.

## Arguments
User provided: $ARGUMENTS

Expected format:
- `/rebase` - Rebase current branch on latest main

## Instructions

### 1. Store Current Branch
- Get current branch: `git branch --show-current`
- Store as WORK_BRANCH
- Validate not on main:
  - If WORK_BRANCH == "main": Error "Cannot rebase main onto itself"
  - Exit

### 2. Checkout and Update Main
- Checkout main: `git checkout main`
- Pull latest: `git pull`
- Report any updates pulled

### 3. Return to Work Branch
- Checkout work branch: `git checkout $WORK_BRANCH`

### 4. Rebase on Main
- Start rebase: `git rebase main`
- Capture exit code to detect conflicts

### 5. Handle Conflicts (if any)
- If rebase encounters conflicts:
  - List conflicted files: `git diff --name-only --diff-filter=U`
  - For each conflicted file:
    - Show conflict context: `git diff <file>`
    - **Conflict Resolution Strategy:**
      - Analyze conflict markers (<<<<<<< HEAD, =======, >>>>>>> main)
      - Apply intelligent resolution based on:
        - If changes are in different sections: Keep both (manual merge)
        - If changes are identical: Accept either
        - If changes conflict semantically: Prefer main (theirs) with warning
        - Document each decision made
    - Resolve using: `git checkout --theirs <file>` or `git checkout --ours <file>` or manual edit
    - Stage resolved file: `git add <file>`
  - **Transparency Report:**
    - List each file with conflicts
    - Show resolution strategy used for each
    - Highlight any files that needed manual intervention
  - Continue rebase: `git rebase --continue`
  - Repeat until rebase completes

### 6. Verify Rebase Success
- Confirm rebase completed: `git status`
- Show rebase summary: `git log --oneline main..HEAD`

### 7. Force Push to Remote
- Force push with lease (safer): `git push --force-with-lease origin $WORK_BRANCH`
- Confirm push succeeded
- Report final status

## Conflict Resolution Strategies

The rebase command will attempt to resolve conflicts intelligently:

1. **Non-overlapping changes**: Keep both changes (manual merge)
2. **Identical changes**: Accept either version
3. **Overlapping changes**:
   - Default: Accept incoming (main) changes with warning
   - Rationale: Main represents the agreed-upon state
   - User should review post-rebase if concerns exist

**All resolution decisions will be reported transparently.**

## Safety Guardrails

- NEVER rebase main onto itself
- ALWAYS use `--force-with-lease` instead of `--force`
- ALWAYS report conflict resolution decisions
- VERIFY rebase completed before force pushing
- If unable to auto-resolve conflicts, abort rebase and report to user
- Warn user to review changes after complex conflict resolution

## Examples

**Basic rebase:**
```
/rebase
```

**Common scenarios:**
```
# After main has been updated with new commits
/rebase

# Before creating a PR to ensure clean history
/rebase

# After PR feedback to incorporate main changes
/rebase
```

## Abort Strategy

If automatic conflict resolution fails:
1. Run: `git rebase --abort`
2. Return to original state
3. Report conflicts to user with suggestion to resolve manually
4. Recommend: `git rebase -i main` for interactive resolution

## Reference Documentation
- **Commands**: `commands/pull_main.md` for main branch operations
- **Git Rebase**: https://git-scm.com/docs/git-rebase
- **CLAUDE.md**: Safety Guardrails section
