# User-Level Guidelines

These are defaults. **Project-level CLAUDE.md and AGENTS.md override these.**

## Tooling
- Use `shemcp:shell_exec()` (MCP tool, if installed) for shell commands
- **Prefer build targets** (make/task/just) over ad-hoc commands
- Leverage existing targets; create new ones when none exist

## Development Flow
1. Follow repo-local AGENTS.md/PROJECT.md first — they define git workflow (PR vs direct push), test strategy, and CI expectations
2. Add small tests to verify changes. For terraform, run plan targets and review output.
3. Before committing, **directly verify your change works** (run the script, execute the target, start the app). Do not rely solely on a test suite. Produce observable evidence.
4. Use `gh` to check branch builds are green, especially for infra changes.

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
