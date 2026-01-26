---
name: gh_pr_merge
description: Merge strategy with final checks, squash by default, safe fallbacks.
inputs: { repo: required, pr_number: required }
outputs: { merge_result: markdown }
dependencies: [ gh CLI ]
safety: Requires green checks. No formal GitHub approvals used or required - agent posts review comments and merges based on its assessment.
steps:
  - Verify required checks are green.
  - If mergeable, squash-merge; else comment with rebase instructions (no formal approval).
  - Post-merge: note follow-up tasks (changelog, release triggers).
tooling:
  - commands: bin/gh-pr-merge
  - gh pr checks; gh pr merge --squash
---
