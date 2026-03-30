# Osterman Claude Configuration

Pragmatic Claude Code/Codex configuration for software and infrastructure work.

## What This Repo Actually Contains

This repository ships a small set of reusable building blocks:

- `AGENTS.md` and `CLAUDE.md` for global working rules
- `agents/` for role prompts
- `skills/` for task-specific guidance
- `hooks/` for safety and telemetry
- `bin/` for helper scripts
- `settings.json` for Claude hook and permission configuration

It does not currently ship a built-in end-to-end `ship_with_review` workflow.

## Included Agents

- `pe` for production engineering and infra-oriented work
- `swe` for implementation work
- `doc` for documentation updates

## Included Skills

- `orientation`
- `documentation`
- `investigate`
- `pull_main`
- `rebase`
- `stability_checks`
- `tf_plan_only`
- `iac`
- `infra_change_review`
- `map-repo`
- `enforce-sourcecode-size`

Each skill lives under `skills/<name>/SKILL.md`.

## Included Hooks

- `hooks/pre_safety_check.sh` blocks or gates risky operations
- `hooks/post_telemetry.sh` writes telemetry when `CLAUDE_TELEMETRY=1`

## Included Helper Scripts

The `bin/` directory contains helpers for common GitHub and Terraform tasks, including:

- `gh-issue-triage`
- `gh-dependency-detect`
- `gh-pr-review`
- `gh-pr-merge`
- `tf-plan-only`
- `ci-fail-investigate`
- `test-health-report`
- `context-scope`
- `diff-summarize`

See `BIN_SCRIPTS.md` for details.

## How To Use It

Use the agents when you want broad role guidance:

```text
Use the swe agent to implement issue #123. Start with pull_main and stability_checks, then make the smallest safe change.
```

Use the skills when you want a specific workflow:

```text
Use tf_plan_only for ./infra in the staging workspace and summarize the risk.
```

```text
Use documentation to update the installation guide after changing hook behavior.
```

## Installation

User-level install:

```bash
git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude
cd ~/.claude
make test
```

Project-level install is also supported. See `INSTALLATION.md`.

## Current Shape Of The Repo

- `skills/` contains the main reusable workflow guidance
- `agents/` provides role prompts layered on top of the shared rules
- `hooks/` and `settings.json` enforce safety and telemetry

If you want a fully automated issue-to-merge workflow, you need to define that explicitly or add it back as a skill. It is not part of the current repository state.
