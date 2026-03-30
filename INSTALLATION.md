# Installation Guide

Install this repository as a Claude Code configuration at either user level or project level.

## Prerequisites

Required:

- `git`
- `jq`

Recommended:

- `make` for running `make test`
- `gh` if you want to use the GitHub helper scripts
- `terraform` if you want to use the Terraform helper scripts

## User-Level Install

Install into `~/.claude`:

```bash
git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude
cd ~/.claude
make test
```

## Project-Level Install

Install into `.claude/` inside a repository:

```bash
git clone https://github.com/YOUR_USERNAME/osterman.git .claude
cd .claude
make test
```

## Hook Paths

`settings.json` currently points hook commands at `~/.claude/hooks/...`.

That works directly for a user-level install. For a project-level install you have two choices:

1. Keep using user-level hooks from `~/.claude/hooks/`.
2. Edit `settings.json` to point at the project-local `.claude/hooks/` directory instead.

## What Gets Installed

This repository currently includes:

- shared instruction files
- agent definitions in `agents/`
- skills in `skills/*/SKILL.md`
- hooks in `hooks/`
- helper scripts in `bin/`

It does not currently include slash commands.

## Verification

Run the repository validation target:

```bash
make test
```

You can also test the hooks directly.

Safety hook example:

```bash
printf '%s\n' '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | ~/.claude/hooks/pre_safety_check.sh
```

Expected result: JSON with `"decision": "block"`.

Telemetry hook example:

```bash
printf '%s\n' '{"tool_name":"Bash","session_id":"demo","cwd":"/tmp","tool_input":{"command":"echo ok"}}' | CLAUDE_TELEMETRY=1 ~/.claude/hooks/post_telemetry.sh
```

Expected result: JSON with `"decision": "approve"` and a telemetry entry written under `~/.claude/telemetry.jsonl` or `$CLAUDE_PROJECT_DIR/.claude/telemetry.jsonl`.

## Customization

Typical customization points:

- edit `AGENTS.md` or `CLAUDE.md` for policy changes
- add or adjust agent files in `agents/`
- add new skills under `skills/<name>/SKILL.md`
- update `settings.json` for permissions or hook changes

After changes, rerun:

```bash
make test
```
