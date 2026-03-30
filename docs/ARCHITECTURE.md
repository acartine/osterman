# Osterman Architecture

## Overview

This repository is a Claude Code configuration organized around a few simple layers:

```text
User request
  -> shared instructions (`AGENTS.md`, `CLAUDE.md`)
  -> role context (`agents/`)
  -> task guidance (`skills/`)
  -> execution helpers (`bin/`)
  -> safety and telemetry (`hooks/`, `settings.json`)
```

The repo is modular. It does not currently contain a built-in `ship_with_review` workflow.

## Directory Map

### Root policy files

- `AGENTS.md` defines the default repo-level operating rules
- `CLAUDE.md` adds higher-level planning and workflow guidance
- `settings.json` configures permissions and hook execution

### Agents

Role prompts live in `agents/`:

- `agents/pe.md`
- `agents/swe.md`
- `agents/doc.md`

Use an agent when you want broad context for a kind of work, such as implementation, infrastructure, or documentation.

### Skills

Skills live as directories containing `SKILL.md` files:

- `skills/orientation/SKILL.md`
- `skills/documentation/SKILL.md`
- `skills/investigate/SKILL.md`
- `skills/pull_main/SKILL.md`
- `skills/rebase/SKILL.md`
- `skills/stability_checks/SKILL.md`
- `skills/tf_plan_only/SKILL.md`
- `skills/iac/SKILL.md`
- `skills/infra_change_review/SKILL.md`
- `skills/map-repo/SKILL.md`
- `skills/enforce-sourcecode-size/SKILL.md`

Use a skill when you want a specific workflow rather than a broad role prompt.

### Hooks

Executable hooks live in `hooks/`:

- `hooks/pre_safety_check.sh`
- `hooks/post_telemetry.sh`

`pre_safety_check.sh` is the safety gate. `post_telemetry.sh` writes telemetry entries when telemetry is enabled.

### Helper scripts

Reusable scripts live in `bin/`:

- GitHub helpers such as `gh-pr-review`, `gh-pr-merge`, and `gh-issue-triage`
- Terraform helpers such as `tf-plan-only`
- Investigation helpers such as `ci-fail-investigate`, `context-scope`, and `diff-summarize`

## How Requests Flow

### Example: implementation task

```text
User asks for a code change
  -> shared rules from AGENTS.md and CLAUDE.md apply
  -> `agents/swe.md` can add implementation-specific context
  -> optional skills like `pull_main` or `stability_checks` provide narrower guidance
  -> helper scripts may be used for GitHub or diff inspection
  -> hooks enforce safety and record telemetry
```

### Example: Terraform planning task

```text
User asks for plan-only Terraform work
  -> `agents/pe.md` provides infra context
  -> `skills/tf_plan_only/SKILL.md` defines the plan-only workflow
  -> `bin/tf-plan-only` can be used as the execution helper
  -> `hooks/pre_safety_check.sh` blocks direct apply paths when needed
```

## Design Intent

The current design favors composable pieces over one monolithic workflow:

- agents provide role context
- skills provide bounded workflows
- scripts provide reusable execution
- hooks provide safety and audit behavior

That keeps the repo easier to maintain, but it also means users need to ask for the workflow they want more explicitly.
