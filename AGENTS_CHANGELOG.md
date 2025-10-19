# Agents & Skills Changelog

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
