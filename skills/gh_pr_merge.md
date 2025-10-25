---
name: gh_pr_merge
description: Merge strategy with final checks, squash by default, safe fallbacks.
inputs: { repo: required, pr_number: required }
outputs: { merge_result: markdown }
dependencies: [ gh CLI ]
safety: Requires green checks. Formal GitHub approvals are not checked - agent's own review drives merge decision.
steps:
  - Verify required checks are green.
  - If mergeable, squash-merge; else approve + comment with rebase instructions.
  - Post-merge: note follow-up tasks (changelog, release triggers).
tooling:
  - commands: bin/gh-pr-merge
  - gh pr checks; gh pr merge --squash
---
