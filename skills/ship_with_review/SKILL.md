---
name: ship_with_review
description: End-to-end workflow from GitHub issue to merged PR with automated third-party review loop. Use when user invokes explicitly, or any request to address a github issue.
---

# Ship With Review Skill

## Overview

Complete workflow that takes a GitHub issue from start to merged PR, including an automated third-party code review loop. Handles iteration when review requests changes or CI fails.


Traditional AI-assisted development suffers from **operator thrashing**—the human becomes a bottleneck, repeatedly reviewing code and requesting changes. This defeats the purpose of autonomous agents.

The `ship_with_review` skill solves this by delegating code review to a third-party AI (Codex) instead of the operator:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Implement  │────►│   Codex     │────►│ APPROVED?   │
│  Solution   │     │   Review    │     │             │
└─────────────┘     └─────────────┘     └──────┬──────┘
       ▲                                       │
       │            NEEDS_WORK                 │
       └───────────────────────────────────────┘
```

**Benefits:**
- **No operator thrashing**: Kick off the workflow and check back when it's done
- **Consistent review quality**: Every PR gets the same thorough automated review
- **Faster iteration**: Agent addresses feedback immediately without waiting for human availability
- **Operator as escalation path**: Humans only intervene when automation hits its limits (max 5 review iterations, max 3 CI fix attempts)

## Coding guidelines
- When adding new functions, the maximum length is 75 lines.
- When adding new files, the maximum size is 500 lines.
- If an existing function is more than 75 lines long, don't add new logic to it.  Add a new function and reference the new function from the old one.
- If an existing file is more than 500 lines long, don't add new logic or data types to it.  Create new file(s) and reference them from the old one.
- Increasing function and file sizes beyond limits is ok IF the increase was simply to reference your new code.

## Inputs
A Github Issue Id for the repo

## Instructions
Follow this as closely as you can.
### Phase 1: Issue Analysis

#### Pre-conditions
- Valid issue number provided
- Repository is accessible

#### Steps
```bash
# Fetch issue details
gh issue view <issue> --repo <repo> --json title,body,labels,assignees,milestone

ASSERT: Issue exists and is open (or has actionable state)

# Understand requirements, acceptance criteria, and scope
```

#### Post-conditions
- Issue requirements are understood
- Ready to check for existing PRs

### Phase 2: Implementation

#### Pre-conditions
- Issue has been analyzed and requirements understood

#### Steps
1. Ensure main is up-to-date:
   ```
   ASSERT: git checkout main && git pull origin main succeeds
   ```
2. Run stability_checks (phase=preparation):
   ```
   ASSERT: Stability checks pass before starting work
   ```
3. **Check if issue already has an associated PR:**

```bash
# Find PRs that reference this issue
gh pr list --repo <repo> --search "<issue>" --json number,headRefName,state,merged
```

**Decision tree:**

```
3) Does issue have an existing PR?
   │
   ├─► NO existing PR
   │   └─► 3a) Create worktree for new feature branch:
   │            git worktree add ../repo-issue-<issue> -b issue-<issue>
   │            → Continue to step 4
   │
   └─► YES existing PR
       │
       └─► 3b) Is the PR merged?
           │
           ├─► NO (PR is open or closed-not-merged)
           │   └─► 3b1) Create worktree from existing PR branch:
           │              git fetch origin <pr-branch>
           │              git worktree add ../repo-issue-<issue> <pr-branch>
           │              → Continue to step 4 (taking existing code into account)
           │
           └─► YES (PR is merged)
               │
               └─► 3b2) Does the merged code resolve the issue?
                   │    (Analyze issue requirements vs merged changes)
                   │
                   ├─► NO (issue not fully resolved)
                   │   └─► 3b2a) Create worktree for new feature branch:
                   │              git worktree add ../repo-issue-<issue> -b issue-<issue>-followup
                   │              → Continue to step 4
                   │
                   └─► YES (issue is resolved)
                       └─► 3b2b) Close the issue and EXIT workflow:
                                gh issue close <issue> --repo <repo> --comment "Resolved by merged PR #<pr>"
                                → WORKFLOW COMPLETE (skip remaining phases)
```

4. Change to worktree directory:
   ```
   ASSERT: Current directory is the worktree
   ```
5. Implement the solution based on issue requirements and coding guidelines above.
6. Run tests and stability_checks (phase=pre-push):
   ```
   ASSERT: All local tests pass
   ```
7. Commit and push:
   ```
   ASSERT: Changes have been committed and pushed to remote
   ```

#### Post-conditions
- Implementation complete
- All new functions are <= 75 lines
- All new files are <= 500 lines
- No function was extended beyond 75 lines except to refer elsewhere
- No file was extended beyond 500 lines except to refer elsewhere
- Changes pushed to remote branch
- Ready to create/update PR

### Phase 3: Create or Update PR

#### Pre-conditions
- Implementation is complete
- Changes have been pushed to remote

**If new branch (cases 3a, 3b2a):**
```bash
# Create draft PR linked to issue
gh pr create --draft --title "<title>" --body "Closes #<issue>

## Summary
<implementation summary>

## Test Plan
<verification steps>
"

# Mark ready for review
gh pr ready
```

**If existing PR branch (case 3b1):**
```bash
# PR already exists - just push changes (done in Phase 2 step 7)
# Optionally update PR body with new summary
gh pr edit <pr_number> --body "Updated implementation...

## Summary
<implementation summary>

## Test Plan
<verification steps>
"
```

#### Post-conditions
- PR exists and is in "open" state
- PR is marked ready for review (not draft)
- Ready to trigger third-party review

### Phase 4: Third-Party Review Loop

#### Pre-conditions
- PR has been created or updated
- Changes have been pushed to remote

#### Trigger Review
```bash
# Run codex review from the worktree directory
codex exec -c model_reasoning_summary="none" -c model_verbosity="low" -c hide_agent_reasoning=true \
  "review this branch against main and format your response as JSON with a status field that says one of the following: NEEDS_WORK, APPROVED" \
  2>/dev/null
```

#### Parse Review Response
The review returns JSON with a `status` field:
- `APPROVED`: Continue to CI check phase
- `NEEDS_WORK`: Extract feedback and iterate

#### Post Review to PR
```bash
# Post the review findings as a PR comment
gh pr comment <pr_number> --repo <repo> --body "<review_content>"
```

#### Review Loop
```
LOOP:
  1. Trigger codex review
  2. Parse response JSON
  3. Post review to PR
  4. IF status == "APPROVED":
       - GOTO Phase 5 (Poll CI)
  5. IF status == "NEEDS_WORK":
       - GOTO Handle NEEDS_WORK
```

#### Handle NEEDS_WORK
```
ASSERT: Review status is NEEDS_WORK with actionable feedback

1. Parse the review feedback

2. Make necessary code changes

3. Run tests and stability_checks (phase=pre-push):
   ASSERT: Local tests pass before pushing

4. Commit and push:
   git add -A && git commit -m "fix: address review feedback" && git push
   ASSERT: Changes have been pushed to remote

5. GOTO Trigger Review (restart the loop)
```

#### Post-conditions (on APPROVED)
- Review status is APPROVED
- Ready to proceed to CI polling phase

#### Timeout
- Maximum review iterations: 5
- If exceeded, pause and notify operator for manual intervention

### Phase 5: CI Green Loop

#### Pre-conditions
- PR has been created and is ready for review
- Codex review has returned `APPROVED`

#### Poll for CI Status
```bash
# Check PR status
gh pr checks <pr_number> --repo <repo>
```

#### Polling Loop
```
LOOP:
  1. Check CI status
  2. IF status == "pending" or "in_progress":
       - Wait 30 seconds
       - GOTO LOOP
  3. IF status == "completed":
       - IF all checks passed:
           - GOTO Merge Phase
       - ELSE (any check failed):
           - GOTO Fix CI Issues
```

#### Polling Configuration
```
interval: 30 seconds
timeout: 10 minutes (max wait for pending checks)
max_fix_iterations: 3
```

#### Fix CI Issues (when checks fail)
```
ASSERT: CI checks have completed with at least one failure

1. Fetch failed check logs:
   gh run view <run_id> --log-failed

2. Analyze failures and identify root cause

3. Implement fixes in worktree

4. Run tests locally to verify fix:
   - Run stability_checks (phase=pre-push)

5. Commit and push:
   git add -A && git commit -m "fix: address CI failures" && git push

ASSERT: Changes have been pushed to remote

6. GOTO Poll for CI Status (restart the loop)
```

#### Post-conditions (on success)
- All CI checks are passing
- Ready to proceed to merge phase

#### Timeout Handling
- If pending checks exceed 10 minutes: pause and notify operator
- If fix iterations exceed 3: pause and notify operator for manual intervention

### Phase 6: Merge

#### Pre-conditions
- All CI checks are passing
- Review status is APPROVED

#### Pre-merge Verification
```bash
# Final check that PR is mergeable
gh pr view <pr_number> --repo <repo> --json mergeable,mergeStateStatus
```

```
ASSERT: mergeable == true
ASSERT: mergeStateStatus == "CLEAN" or "UNSTABLE" (no blocking issues)
```

#### Squash Merge
```bash
gh pr merge <pr_number> --repo <repo> --squash --delete-branch
```

```
ASSERT: Merge command exits with status 0
ASSERT: PR state is now "MERGED"
```

#### Post-conditions
- PR has been merged to main
- Remote branch has been deleted

### Phase 7: Cleanup

#### Pre-conditions
- PR has been successfully merged
- Currently in worktree directory

#### Steps
```bash
# Return to main repo directory
cd <original_repo_path>

ASSERT: Current directory is the main repository (not worktree)

# Checkout main and pull
git checkout main
git pull origin main

ASSERT: Local main branch is up-to-date with merged changes

# Remove worktree
git worktree remove ../repo-issue-<issue>

ASSERT: Worktree directory no longer exists
```

#### Post-conditions
- Local main branch contains the merged changes
- Worktree has been cleaned up
- Ready for next task

## State Machine

```
┌─────────────────┐
│  Read Issue     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Check for      │
│  Existing PR    │
└────────┬────────┘
         │
         ▼
    ┌────────────┐
    │ Has PR?    │
    └─────┬──────┘
          │
    ┌─────┴─────┐
    │           │
   NO          YES
    │           │
    ▼           ▼
┌────────┐  ┌────────────┐
│ Create │  │ PR Merged? │
│ New    │  └─────┬──────┘
│ Branch │        │
└───┬────┘  ┌─────┴─────┐
    │       │           │
    │      NO          YES
    │       │           │
    │       ▼           ▼
    │  ┌─────────┐  ┌────────────┐
    │  │ Checkout│  │ Resolved?  │
    │  │ Existing│  └─────┬──────┘
    │  │ Branch  │        │
    │  └────┬────┘  ┌─────┴─────┐
    │       │       │           │
    │       │      NO          YES
    │       │       │           │
    │       │       ▼           ▼
    │       │  ┌─────────┐  ┌─────────────┐
    │       │  │ Create  │  │ Close Issue │
    │       │  │ Followup│  │ EXIT        │
    │       │  │ Branch  │  └─────────────┘
    │       │  └────┬────┘
    │       │       │
    └───────┴───────┘
            │
            ▼
┌─────────────────┐
│  Implement      │◄─────────────────┐
└────────┬────────┘                  │
         │                           │
         ▼                           │
┌─────────────────┐                  │
│  Create PR      │                  │
│  (if needed)    │                  │
└────────┬────────┘                  │
         │                           │
         ▼                           │
┌─────────────────┐    NEEDS_WORK    │
│  Codex Review   │──────────────────┘
└────────┬────────┘
         │ APPROVED
         ▼
         ┌──────────────────────────┐
         │                          │
         ▼                          │
┌─────────────────┐                 │
│  Poll CI        │──► NOT DONE ────┘
└────────┬────────┘    (wait 30s)
         │ DONE
         ▼
    ┌───────────┐
    │ Passing?  │
    └─────┬─────┘
          │
    ┌─────┴─────┐
    │           │
   YES         NO
    │           │
    │           ▼
    │  ┌─────────────────┐
    │  │  Fix CI Issues  │
    │  └────────┬────────┘
    │           │
    │           ▼
    │  ┌─────────────────┐
    │  │  Push Fixes     │───► (back to Poll CI)
    │  └─────────────────┘
    │
    ▼
┌─────────────────┐
│  Squash Merge   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Cleanup        │
└─────────────────┘
```

## Error Handling

### Review Timeout
If codex review times out or fails:
1. Log the error
2. Retry once
3. If still failing, post PR comment and pause for operator

### CI Timeout
If CI doesn't complete within timeout:
1. Check for stuck/queued jobs
2. Post PR comment with status
3. Pause for operator decision

### Merge Conflicts
If PR becomes unmergeable:
1. Rebase on main: `git rebase origin/main`
2. Resolve conflicts
3. Force push: `git push --force-with-lease`
4. Re-trigger review loop

## Example Invocation

```
# Ask the agent to use the skill
"Ship issue #42 using the ship_with_review skill"

# Or reference directly
"Use ship_with_review to implement and merge issue #42"
```

## Safety Notes

- Never force-push to main
- Always verify CI is green before merge
- Preserve PR history with squash merge
- Clean up worktrees after completion
