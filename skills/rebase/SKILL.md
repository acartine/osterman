---
name: rebase
description: Rebase current work branch on latest main with intelligent conflict resolution.
inputs: {}
outputs: { status: string, conflicts_resolved: array }
dependencies: [ git ]
safety: Modifies branch history; uses --force-with-lease for safer force push.
steps:
  - Store current branch name
  - Checkout main and pull latest
  - Return to work branch
  - Rebase on main
  - Resolve conflicts automatically with transparency
  - Force push with lease
tooling:
  - git checkout, git pull, git rebase, git push --force-with-lease
---

# Rebase Skill

## Overview
Automates rebasing the current work branch on the latest main, including intelligent conflict resolution and safe force pushing.

## Usage
```bash
# Store current branch
WORK_BRANCH=$(git branch --show-current)

# Validate not on main
if [ "$WORK_BRANCH" == "main" ]; then
  echo "Error: Cannot rebase main onto itself"
  exit 1
fi

# Update main
git checkout main
git pull

# Return to work branch and rebase
git checkout $WORK_BRANCH
git rebase main

# Handle conflicts if they occur (see conflict resolution strategy below)

# Force push with lease (safer than --force)
git push --force-with-lease origin $WORK_BRANCH
```

## Conflict Resolution Strategy

When conflicts occur during rebase:

1. **List conflicted files**: `git diff --name-only --diff-filter=U`

2. **For each conflicted file, analyze and resolve**:
   - **Non-overlapping changes**: Keep both (manual merge)
   - **Identical changes**: Accept either version
   - **Overlapping changes**: Default to accepting incoming (main) changes
     - Rationale: Main represents the agreed-upon state
     - Always warn when using this strategy

3. **Resolution commands**:
   ```bash
   # Accept incoming (main) changes
   git checkout --theirs <file>

   # Accept current (work branch) changes
   git checkout --ours <file>

   # Manual merge (for complex cases)
   # Edit file directly to resolve conflicts

   # Stage resolved file
   git add <file>
   ```

4. **Continue rebase**: `git rebase --continue`

5. **Repeat until complete**

## Transparency Reporting

Always report:
- List of files with conflicts
- Resolution strategy used for each file
- Any files requiring manual review
- Final rebase summary: `git log --oneline main..HEAD`

## Safety

- **Validates**: Never rebase main onto itself
- **Uses --force-with-lease**: Prevents overwriting unexpected remote changes
- **Abort on failure**: If unable to auto-resolve, run `git rebase --abort`
- **Transparency**: Always report resolution decisions made

## Abort Strategy

If automatic conflict resolution fails:
```bash
git rebase --abort
```
Then report to user with suggestion to resolve manually via `git rebase -i main`

## Common Use Cases

- Rebase feature branch before creating PR (clean history)
- Incorporate latest main changes into work branch
- Resolve conflicts with main after updates
- Clean up commit history before merge

## Safety Notes

- Changes branch history (commits will have new SHAs)
- Requires force push (uses safer `--force-with-lease`)
- May conflict with ongoing work if others are on the same branch
- Review changes after complex conflict resolution
