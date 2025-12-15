---
name: impl_worktree_workflow
description: Worktree-based implementation workflow for parallel development, aligned with CLAUDE.md.
inputs: { task: required }
outputs: { checklist: markdown }
dependencies: [ git, gh, project make/task targets, stability_checks ]
safety: Non-destructive by default; follow CLAUDE.md guardrails.
steps:
  - Ensure main is up-to-date (pull from origin).
  - Run stability_checks skill (phase=preparation) to verify main is stable.
  - Create a worktree for the feature branch (e.g., `git worktree add ../repo-feature-x -b feature-x`).
  - Change to the worktree directory and implement incrementally.
  - Run tests and smoke tests via existing targets.
  - Run stability_checks skill (phase=pre-push) before pushing.
  - Push, open DRAFT PR, iterate until green, then mark ready.
  - After merge, clean up worktree: `git worktree remove ../repo-feature-x`.
tooling:
  - commands: bin/impl-worktree-workflow
  - git/gh; make/task; test runners
related_skills: [ stability_checks ]
---
