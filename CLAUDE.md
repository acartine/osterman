# User-Level Guidelines

These are defaults. **Project-level CLAUDE.md and AGENTS.md override these.**

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Demand Elegance (Balanced)**: For non-trivial changes, pause and ask "is there a more elegant way?" Skip this for simple, obvious fixes — don't over-engineer.

## Planning
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions).
- If something goes sideways, STOP and re-plan immediately — don't keep pushing.
- Use plan mode for verification steps, not just building.
- Write detailed specs upfront to reduce ambiguity.

## Subagent Strategy
- Use subagents liberally to keep main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, throw more compute at it via subagents.
- One task per subagent for focused execution.

## Tooling
- Use `shemcp:shell_exec()` (MCP tool, if installed) for shell commands.
- **Prefer build targets** (make/task/just) over ad-hoc commands.
- Leverage existing targets; create new ones when none exist.

## Development Flow
1. Follow repo-local AGENTS.md/PROJECT.md first — they define git workflow (PR vs direct push), test strategy, and CI expectations.
2. Add small tests to verify changes. For terraform, run plan targets and review output.
3. Before committing, **directly verify your change works** (run the script, execute the target, start the app). Do not rely solely on a test suite. Produce observable evidence.
4. Use `gh` to check branch builds are green, especially for infra changes.

## Task Management
1. **Plan First**: Write plan to `tasks/todo.md` with checkable items.
2. **Verify Plan**: Check in before starting implementation.
3. **Track Progress**: Mark items complete as you go.
4. **Explain Changes**: High-level summary at each step.
5. **Document Results**: Add review section to `tasks/todo.md`.
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections.

## Verification Before Done
- Never mark a task complete without proving it works.
- Diff behavior between main and your changes when relevant.
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness.

## Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them.
- Zero context switching required from the user.
- Go fix failing CI tests without being told how.

## Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern.
- Write rules for yourself that prevent the same mistake.
- Ruthlessly iterate on these lessons until mistake rate drops.
- Review lessons at session start for relevant project.

## Commits
- Clear, imperative titles (≤72 chars). Scope when helpful (e.g., "frontend: fix login redirect").
- Never commit secrets.

## Autonomy Policy
Operate autonomously for routine work. **Require explicit approval before:**
- `terraform apply`, `kubectl apply/delete` against non-kind contexts
- Production database schema/data changes and migrations
- Secret/key rotations, IAM policy changes, token scope expansion
- DNS, TLS/SSL, CDN, or WAF changes
- Destructive or irreversible operations (delete/purge/backfill)
- Changes likely to incur material cloud costs

**Pause and ask when:** CI is red, permissions are insufficient, or risk feels unclear.

## Safety
- Plan/dry-run first for all infra: `terraform plan`, `kubectl diff`, `helm template`
- Prefer non-destructive, incremental changes; propose rollbacks before executing
- Never commit or log secrets; prefer env vars and vaults
