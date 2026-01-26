---
name: third_party_review
description: Trigger an automated third-party code review using Codex and iterate until approved. Use when you need an independent code review on a PR or branch.
inputs: { pr_number: optional, repo: optional }
outputs: { status: APPROVED|NEEDS_WORK, review_content: string }
dependencies: [ codex, gh, git ]
safety: Read-only analysis; posts review comments to PR.
---

# Third-Party Review Skill

## Overview

Delegates code review to a third-party AI (Codex) instead of the operator. This eliminates operator thrashing by providing consistent, automated review feedback that the agent can iterate on immediately.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Current    │────►│   Codex     │────►│ APPROVED?   │
│  Branch     │     │   Review    │     │             │
└─────────────┘     └─────────────┘     └──────┬──────┘
       ▲                                       │
       │            NEEDS_WORK                 │
       └───────────────────────────────────────┘
```

**Benefits:**
- **No operator thrashing**: Get automated review feedback without human bottleneck
- **Consistent review quality**: Every PR gets the same thorough review
- **Faster iteration**: Agent addresses feedback immediately
- **Operator as escalation path**: Humans only intervene when automation hits limits

## Inputs

- `pr_number` (optional): PR number to review. If not provided, reviews current branch against main.
- `repo` (optional): Repository in owner/repo format. Defaults to current repo.

## Pre-conditions

- PR has been created or changes have been pushed to remote
- Current directory is the worktree or repo with the changes to review

## Instructions

### Step 1: Trigger Review

Run codex review from the worktree/branch directory:

```bash
codex exec -c model_reasoning_summary="none" -c model_verbosity="low" -c hide_agent_reasoning=true \
  "review this branch against main and format your response as JSON with a status field that says one of the following: NEEDS_WORK, APPROVED" \
  2>/dev/null
```

### Step 2: Parse Review Response

The review returns JSON with a `status` field:
- `APPROVED`: Review passed, continue to next phase
- `NEEDS_WORK`: Extract feedback and iterate

### Step 3: Post Review to PR (if PR exists)

```bash
# Post the review findings as a PR comment
gh pr comment <pr_number> --repo <repo> --body "<review_content>"
```

### Step 4: Review Loop

```
LOOP:
  1. Trigger codex review
  2. Parse response JSON
  3. Post review to PR (if applicable)
  4. IF status == "APPROVED":
       - EXIT with APPROVED status
  5. IF status == "NEEDS_WORK":
       - GOTO Handle NEEDS_WORK
```

### Step 5: Handle NEEDS_WORK

```
ASSERT: Review status is NEEDS_WORK with actionable feedback

1. Parse the review feedback

2. Make necessary code changes

3. Run tests and stability_checks (phase=pre-push):
   ASSERT: Local tests pass before pushing

4. Commit and push:
   git add -A && git commit -m "fix: address review feedback" && git push
   ASSERT: Changes have been pushed to remote

5. GOTO Step 1 (Trigger Review - restart the loop)
```

## Post-conditions

- Review status is APPROVED, OR
- Maximum iterations reached and operator notified

## Configuration

```
max_review_iterations: 5
```

## Timeout Handling

- Maximum review iterations: 5
- If exceeded, pause and notify operator for manual intervention
- Post a PR comment indicating the review loop has been exhausted

## Error Handling

### Review Timeout or Failure

If codex review times out or fails:
1. Log the error
2. Retry once
3. If still failing, post PR comment and pause for operator

### Example Error Comment

```bash
gh pr comment <pr_number> --repo <repo> --body "Third-party review failed after retries. Manual review required."
```

## Example Invocation

```
# Review current branch
"Run the third_party_review skill on this branch"

# Review a specific PR
"Use third_party_review to review PR #42"

# As part of a larger workflow
"After pushing, trigger third_party_review before merging"
```

## Integration with Other Skills

This skill is typically used as part of the `ship_with_review` workflow, but can be invoked standalone when:
- You want to get automated feedback on work-in-progress
- You need a review before requesting human review
- You want to iterate on code quality before CI runs

## State Machine

```
┌─────────────────┐
│  Trigger Codex  │
│  Review         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Parse Response │
└────────┬────────┘
         │
         ▼
    ┌───────────┐
    │  Status?  │
    └─────┬─────┘
          │
    ┌─────┴─────┐
    │           │
 APPROVED   NEEDS_WORK
    │           │
    ▼           ▼
┌────────┐  ┌─────────────────┐
│  EXIT  │  │  Address        │
│  OK    │  │  Feedback       │
└────────┘  └────────┬────────┘
                     │
                     ▼
            ┌─────────────────┐
            │  Commit & Push  │
            └────────┬────────┘
                     │
                     ▼
            ┌─────────────────┐
            │  Iterations     │
            │  < Max?         │
            └────────┬────────┘
                     │
               ┌─────┴─────┐
               │           │
              YES         NO
               │           │
               │           ▼
               │      ┌─────────────────┐
               │      │  Notify         │
               │      │  Operator       │
               │      └─────────────────┘
               │
               └──────► (back to Trigger Review)
```

## Safety Notes

- This skill does not merge or make destructive changes
- Reviews are posted as comments for transparency
- Operator is always notified when automation limits are reached
- All changes are committed with clear messages for audit trail
