---
name: gh_dependency_detect
description: Identify logical dependencies between issues/PRs via links, keywords, and CI checks.
inputs: { repo: required, items: [issues|prs] }
outputs: { graph: markdown, blockers: list }
dependencies: [ gh CLI ]
safety: Read-only.
steps:
  - Fetch target items and cross-references.
  - Search for keywords: depends on, blocked by, closes, fixes.
  - Inspect PR required checks for blocking status.
  - Produce a dependency graph and prioritized unblock plan.
tooling:
  - commands: bin/gh-dependency-detect
  - gh issue/gh pr list --json; gh pr checks
---
