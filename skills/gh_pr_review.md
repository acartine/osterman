---
name: gh_pr_review
description: Fetch PR diff and perform structured review with severity-tagged feedback.
inputs: { repo: required, pr_number: required }
outputs: { review_summary: markdown, findings: list }
dependencies: [ gh CLI ]
safety: Read-only by default; comments/approvals require approval or agent autonomy.
steps:
  - Fetch diff + metadata (files, labels, checks, size, authors).
  - Run quality checklist: correctness, security, performance, tests, docs.
  - Summarize architectural impacts and risk level.
  - Draft review with Critical/Important/Suggestions.
tooling:
  - commands: bin/gh-pr-review
  - gh pr view --json; git diff; local linters/tests when available
---
