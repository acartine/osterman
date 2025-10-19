---
name: gh_issue_triage
description: Prioritize and label GitHub issues, suggest owners and due dates.
inputs: { repo: required, filters: optional }
outputs: { triage_report: markdown, recommendations: list }
dependencies: [ gh CLI ]
safety: Read-only; does not modify issues unless explicitly approved.
steps:
  - List open issues excluding drafts/spikes per repo filters.
  - Parse labels, assignees, severity keywords; detect duplicates.
  - Propose priority, labels, and owner suggestions.
  - Emit dependency hints (links to related issues/PRs).
tooling:
  - commands: bin/gh-issue-triage
  - gh issue list --label --json
---
