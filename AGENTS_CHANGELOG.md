# Agents & Skills Changelog

## 2025-01-23
- Removed `ship_with_review` command, keeping only the skill
- Updated documentation to reference the skill directly instead of the slash command
- Rationale: skills are the preferred invocation pattern; commands add unnecessary indirection

## 2025-01-22
- Removed `jswe` and `sswe` agents/commands (consolidated into `swe`)
- Elevated `ship_with_review` as THE signature workflow
- Added "Ralph Wiggum Loop" terminology to describe the automated review cycle
  - Named after the Simpsons character: after enough review iterations, even Ralph could approve it
  - Philosophy: minimize operator thrashing by delegating review to Codex
  - Operator becomes escalation path rather than bottleneck
- Simplified documentation to focus on `ship_with_review` skill as the primary entry point

## 2025-01-20
- Added `ship_with_review` skill for end-to-end issue-to-merge workflow with automated third-party code review loop.
  - Reads GitHub issue, implements solution in worktree, creates PR
  - Triggers codex review and iterates on `NEEDS_WORK` feedback (max 5 attempts)
  - Polls for green CI and fixes failures (max 3 attempts)
  - Squash merges on success, cleans up worktree

## 2025-10-23
- Upgraded swe to Opus

## 2025-10-19
- Renamed `team-lead-pr-reviewer` agent to `tl` (big-tech style shorthand).
- Merged `pair-programmer` and `cloud-infra-devops` into `pe` (Production Engineering) hybrid agent: safe autonomy for plan/analysis; confirm-first for high-risk.
- Added autonomy, safety, and token usage policies to `CLAUDE.md`.
- Introduced `skills/` library (GitHub triage/review/merge, CI, Terraform plan-only, context scoping, diff summarization, implementation workflow, architecture planning).
- Introduced `hooks/` (pre_safety, context_trim, post_telemetry, gh_event_heuristics).
- Refactored agents to thin, skill-composed prompts with autonomy flags and hooks.
- Added `RISK_REGISTER.md` and `PROMPTING_GUIDE.md`.

Entry format for future changes
- Date
- Changes (what was added/removed/modified)
- Rationale (why) and impact (token/safety/ergonomics)
