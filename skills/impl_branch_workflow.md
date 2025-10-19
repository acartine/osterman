---
name: impl_branch_workflow
description: Standard branch-based implementation workflow aligned with CLAUDE.md.
inputs: { task: required }
outputs: { checklist: markdown }
dependencies: [ git, gh, project make/task targets ]
safety: Non-destructive by default; follow CLAUDE.md guardrails.
steps:
  - Check out main, pull, verify builds/tests.
  - Create feature branch and implement incrementally.
  - Run tests and smoke tests via existing targets.
  - Push, open DRAFT PR, iterate until green, then mark ready.
tooling:
  - commands: bin/impl-branch-workflow
  - git/gh; make/task; test runners
---
