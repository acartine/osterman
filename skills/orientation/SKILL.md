---
name: orientation
description: Analyze PRs and issues to provide context orientation and actionable next steps.
inputs: { pr: optional, issue: optional, repo: optional }
outputs: { summary: markdown }
dependencies: [ gh, git ]
safety: Read-only analysis, no modifications.
steps:
  - Auto-detect repository from git remote if not specified.
  - Fetch PR/issue details using gh commands.
  - Analyze code changes, CI status, and blockers.
  - Identify dependencies and related work.
  - Provide clear summary with concrete next steps.
tooling:
  - commands: /orient
  - gh for PR/issue data; git for repo detection
---
