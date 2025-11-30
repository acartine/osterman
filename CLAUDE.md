# Repository Guidelines

## Tooling
wherever possible use the shemcp:shell_exec() (the mcp tool, if installed) for bash commands, especially:
- aws
- az
- grep
- sed
- tail
- head
- timeout
- npm
- npx
- task
- make
- test
- openssl
- sleep
- cd
- mkdir

## Best Practices
- Prefer using build file targets (make/task/just) to running ad-hoc commands
- leverage existing targets where it makes sense.  e.g. if you are adding a test, add it in a way that an existing target will pick it up
- if no target exists, consider creating a new target.  this enables discovery and reuse for other users.

## Agent Development Flow
For each unit of work (feature request, bugfix) prompted by the Operator, exercise this general flow of work to complete the task:
1. Ensure main is checked out and up-to-date (pull from origin).
1. Run compile tasks and verify main is compiling.
1. Run all unit tests and verify main is stable.
1. Run smoketests or apps to verify main is working. When running smoketests, use a timeout of 3 minutes. When running apps, launch them in the background for 30 seconds and verify no errors/exceptions.
1. Kill any processes you launched.
1. Create a worktree for your feature/bugfix branch (e.g., `git worktree add ../repo-feature-x -b feature-x`). This enables parallel development across multiple agents without branch switching conflicts.
1. Change to the worktree directory and make edits as requested.
1. Run tests to prevent regression.
1. Add small, simple tests to verify results. For terraform changes, execute the make targets for terraform plan and review them.
1. For non infra changes, smoketest the new logic - look for smoketest make/task targets if applicable. Run all tests. If your tests are failing, fix them or simplify them.
1. Before committing, verify your specific change works by directly executing the component you modified (run the script you fixed, execute the make/task target you changed, start the app to test config changes, etc.). Do NOT just run a test suite unless it specifically exercises your change. You must produce observable evidence that your change works. Only after successful verification, commit your changes and push to remote.
1. Use the gh tool to inspect branch builds and verify green workflows. Inspect the logs if necessary, especially for infra changes.
1. If successful, create a PR.
1. Use the gh tool to monitor PR workflows and verify they are green. Inspect the logs if necessary, especially for infra changes.
1. Prompt the operator that you are ready to merge. Wait until the operator agrees that the PR should be merged.
1. After merge, clean up the worktree: `git worktree remove ../repo-feature-x`.

## Commit & Pull Request Guidelines
- Commits: Use clear, imperative titles (≤72 chars). Scope when helpful (e.g., "frontend: fix login redirect").
- PRs: Include purpose, linked issues, and screenshots/GIFs for UI. Ensure lints/compiles/tests are green. For Terraform PRs, attach the plan output.

## Security & Configuration Tips
- Never commit secrets.

## Project Specific Guidelines
- Read ./PROJECTS.md and treat those guidelines as an appendix to these.

## Autonomy Policy
- Default: Domain agents operate autonomously for routine work in their scope.
- Always require explicit approval before:
  - `terraform apply`, `kubectl apply/delete` against non-kind contexts
  - Production database schema/data changes and migrations
  - Secret/key rotations, IAM role policy changes, or token scope expansion
  - DNS, TLS/SSL certificate, CDN, or WAF changes
  - Destructive operations (delete/purge/backfill) and irreversible data tasks
  - Any change likely to incur material cloud costs (scale-ups, new managed services)
- Pause autonomy and request approval when:
  - CI is red or PR checks fail
  - Permissions are insufficient for an intended action
  - Risk exceeds guardrails in `docs/RISK_REGISTER.md`

## Safety Guardrails
- Use plan/dry-run first for all infra: `terraform plan`, `kubectl diff`, `helm template`, `gh pr status`.
- For Terraform, produce and summarize a plan; do not apply without approval.
- Prefer non-destructive, incremental changes; propose rollbacks before executing.
- Never commit or log secrets; prefer env vars and vaults.
- When uncertain, escalate to the Pair Programming agent (non-autonomous).

## Token Usage Policy
- Prefer scoped context: use `rg` to locate relevant files, include minimal snippets.
- Summarize large diffs/files; avoid pasting full content unless explicitly requested.
- Centralize shared procedures in skills and hooks; agents should reference them rather than inline.
- Use progressive disclosure: start with summaries and expand on demand.
- Reuse existing build/test targets; avoid verbose command listings.

## Command Shortcuts
- Messages starting with `/` are treated as project-local shortcuts (handled by the `command_router` hook) that expand into agent + skill actions.
- Supported examples:
  - `/pe plan DIR=./infra WORKSPACE=staging` → Production Engineering agent runs Terraform plan-only and summarizes risk.
  - `/pe apply DIR=./infra WORKSPACE=prod` → Confirm-first flow for applies; requires explicit approval.
  - `/tl review REPO=org/name PR=123` → Team lead PR review; may merge if low risk and green.
  - `/tl triage REPO=org/name` → Issue triage + dependency mapping.
  - `/swe impl TASK="feature-x" SPEC=<link-or-notes>` → Implementation workflow with DRAFT PR.
  - `/test health` → Test health report summary.
  - `/dbg <desc>` → Debugger scopes logs/code and proposes fixes.
  - `/arch plan FEATURE="feature-y"` → Architecture integration plan.
