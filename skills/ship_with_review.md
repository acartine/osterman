---
name: ship_with_review
description: End-to-end workflow from GitHub issue to merged PR with automated third-party review loop.
inputs: { issue: required, repo: optional }
outputs: { pr_url: string, merge_status: string }
dependencies: [ gh CLI, codex CLI, git, make/task targets, stability_checks, impl_worktree_workflow ]
safety: Creates branches, PRs, and merges. Follow CLAUDE.md guardrails. Requires green CI before merge.
steps:
  - Read and analyze GitHub issue.
  - Check if issue has existing PR; if merged and resolved, close issue and exit.
  - Create worktree (new branch or existing PR branch as appropriate).
  - Implement solution using worktree workflow.
  - Create PR (if needed) and trigger third-party review.
  - Poll for review comment (with timeout).
  - If APPROVED, continue; if NEEDS_WORK, iterate on implementation.
  - Poll for green CI (with timeout).
  - If all green, squash merge; if any red, iterate on implementation.
  - Checkout main and pull.
tooling:
  - commands: bin/ship-with-review
  - gh; git; codex; make/task
related_skills: [ impl_worktree_workflow, stability_checks, gh_pr_merge ]
---

# Ship With Review Skill

## Overview
Complete workflow that takes a GitHub issue from start to merged PR, including an automated third-party code review loop. Handles iteration when review requests changes or CI fails.

## Inputs
- `issue`: GitHub issue number (required)
- `repo`: Repository in `owner/repo` format (optional, defaults to current repo)

## Workflow

### Phase 1: Issue Analysis
```bash
# Fetch issue details
gh issue view <issue> --repo <repo> --json title,body,labels,assignees,milestone

# Understand requirements, acceptance criteria, and scope
```

### Phase 2: Implementation (via impl_worktree_workflow)
1. Ensure main is up-to-date
2. Run stability_checks (phase=preparation)
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

4. Change to worktree directory
5. Implement the solution based on issue requirements
6. Run tests and stability_checks (phase=pre-push)
7. Commit and push

### Phase 3: Create or Update PR

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

### Phase 4: Third-Party Review Loop

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

#### Handle NEEDS_WORK
If status is `NEEDS_WORK`:
1. Parse the review feedback
2. Make necessary code changes
3. Run tests and stability_checks (phase=pre-push)
4. Commit and push
5. **Go back to "Trigger Review"**

#### Timeout
- Maximum review iterations: 5
- If exceeded, pause and notify operator for manual intervention

### Phase 5: CI Green Loop

#### Poll for CI Status
```bash
# Check PR status
gh pr checks <pr_number> --repo <repo>
```

#### Polling Strategy
```
interval: 30 seconds
timeout: 10 minutes
```

#### Handle CI Results
- **All green**: Continue to merge phase
- **Any red/failing**:
  1. Fetch failed check logs: `gh run view <run_id> --log-failed`
  2. Analyze failures
  3. Fix issues
  4. Run tests locally
  5. Commit and push
  6. **Go back to "Poll for CI Status"**

#### Timeout
- Maximum CI fix iterations: 3
- If exceeded, pause and notify operator for manual intervention

### Phase 6: Merge

#### Pre-merge Verification
```bash
# Final check that PR is mergeable
gh pr view <pr_number> --repo <repo> --json mergeable,mergeStateStatus
```

#### Squash Merge
```bash
gh pr merge <pr_number> --repo <repo> --squash --delete-branch
```

### Phase 7: Cleanup

```bash
# Return to main repo directory
cd <original_repo_path>

# Checkout main and pull
git checkout main
git pull origin main

# Remove worktree
git worktree remove ../repo-issue-<issue>
```

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
┌─────────────────┐    RED/FAILING
│  Poll CI        │──────────────────┐
└────────┬────────┘                  │
         │ ALL GREEN                 │
         ▼                           │
┌─────────────────┐                  │
│  Squash Merge   │                  │
└────────┬────────┘                  │
         │                           │
         ▼                           │
┌─────────────────┐    Fix & Push    │
│  Cleanup        │◄─────────────────┘
└─────────────────┘   (then re-poll)
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

```bash
# Via command shortcut
/ship_with_review 42

# Or directly
"Ship issue #42 using the ship_with_review skill"
```

## Safety Notes

- Never force-push to main
- Always verify CI is green before merge
- Preserve PR history with squash merge
- Clean up worktrees after completion
- Timeout and iteration limits prevent infinite loops
