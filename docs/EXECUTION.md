# Execution Model

## Current State

The repository currently executes work through four main mechanisms:

1. Shared policy in `AGENTS.md` and `CLAUDE.md`
2. Role prompts in `agents/`
3. Task-specific skills in `skills/*/SKILL.md`
4. Helper scripts and hooks in `bin/`, `hooks/`, and `settings.json`

## What Is Not Shipped

The repository does not currently ship:

- a built-in `ship_with_review` workflow
- a `tl` agent

Any documentation or prompting should assume those are absent unless the repo adds them back.

## Current Execution Paths

### Implementation

Typical implementation work uses:

- `agents/swe.md`
- `skills/pull_main/SKILL.md`
- `skills/stability_checks/SKILL.md`
- `skills/investigate/SKILL.md` when diagnosis should precede changes

### Infrastructure

Typical infra work uses:

- `agents/pe.md`
- `skills/tf_plan_only/SKILL.md`
- `skills/iac/SKILL.md`
- `skills/infra_change_review/SKILL.md`

### Documentation

Typical docs work uses:

- `agents/doc.md`
- `skills/documentation/SKILL.md`
- `skills/map-repo/SKILL.md` when generating repo maps or architecture indexes

## Helper Scripts

The scripts in `bin/` are reusable utilities, not user-facing slash commands. The most commonly useful ones are:

- `bin/gh-pr-review`
- `bin/gh-pr-merge`
- `bin/gh-issue-triage`
- `bin/tf-plan-only`
- `bin/ci-fail-investigate`
- `bin/context-scope`
- `bin/diff-summarize`

## Verification

The simplest validation path for this repository is:

```bash
make test
```

That runs `test/validate-config.sh` against the repo.
