# .claude Config (Agents, Skills, Hooks)

A portable Claude Code configuration you can reuse across projects and machines. It includes:

- Agents: `tl`, `pe`, `swe`, `test-engineer`, `code-debugger`, `software-architect`
- Skills: GitHub triage/review/merge, CI investigation, Terraform plan-only, implementation workflow, context scoping, diff summarization, architecture planning
- Hooks: safety gating, context trimming, telemetry, command router (slash shortcuts)
- Commands: `bin/` helpers for gh, terraform plan-only, tests, context/diff utilities

## Quick Start
- Local usage (project-scoped): keep this folder as `.claude/` at repo root and commit it.
- Global usage (optional): symlink to `~/.claude` and add `~/.claude/bin` to `PATH`.

```
# Global setup (optional)
mv ~/.claude ~/.claude.backup-$(date +%Y%m%d%H%M%S) 2>/dev/null || true
ln -s "$PWD" ~/.claude
export PATH="$HOME/.claude/bin:$PATH"
```

## Slash Shortcuts
Type these directly in Claude chat (handled by the command_router hook):
- `/pe plan DIR=./infra WORKSPACE=staging` — Terraform plan-only summary (no apply)
- `/pe apply DIR=./infra WORKSPACE=prod` — Confirm-first flow for prod apply
- `/tl review REPO=org/name PR=123` — PR review (may merge if green/low risk)
- `/tl triage REPO=org/name` — Issue triage and dependency mapping
- `/swe impl TASK="feature-x" SPEC=<link-or-notes>` — Implementation workflow
- `/test health` — Test health report
- `/dbg failing test LoginFlow` — Debugger flow
- `/arch plan FEATURE="realtime notifications"` — Architecture plan

See `CLAUDE.md` and `PROMPTING_GUIDE.md` for full policy and recipes.

## Bin Commands
Make scripts executable once and use them directly:
```
chmod +x bin/*
REPO=org/name PR=123 bin/gh-pr-review
REPO=org/name PR=123 DRY_RUN=0 bin/gh-pr-merge
DIR=./infra WORKSPACE=staging bin/tf-plan-only
```

## Versioning
- Commit `.claude/` to your repo; `.gitignore` excludes local/transient artifacts.
- For global install, use symlink + backup pattern.

## License
- Add your preferred license if you plan to share publicly.

