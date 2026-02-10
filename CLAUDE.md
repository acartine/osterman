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
**NOTE: If you cannot find a command, make sure you look in the User level settings before you decide the command is not there.**

**NOTE: For each unit of work (feature request, bugfix, etc.), you should almost always default to the ship_with_review skill.  If no Github issue exists for you work, simply omit steps that ask you to do stuff with the Github Issue.  The only exception is if the Operator explicitly tells you to do something different.**

For each unit of work (feature request, bugfix) prompted by the Operator, exercise the general flow of work as closely to the ship_with_review skill as possible.  Some extra suggestions include: 
1. Add small, simple tests to verify results. For terraform changes, execute the make targets for terraform plan and review them.
1. For non infra changes, look in ./PROJECT.md for sanity/stability commands to run when you think your changes satisfy the requirements and the tests have been augmented to support your changes.  If your tests are failing, fix the code or test (whichever is wrong in light of the requirements).  If the test is wrong and super complicated, simplify it and clarify caveats in the test code and the PR.
1. Before committing, verify your specific change works by directly executing the component you modified (run the script you fixed, execute the make/task target you changed, start the app to test config changes, etc.). Do NOT just run a test suite unless it specifically exercises your change. You must produce observable evidence that your change works. Only after successful verification, commit your changes and push to remote.
1. Use the gh tool to inspect branch builds and verify green workflows. Inspect the logs if necessary, especially for infra changes.

## Commit & Pull Request Guidelines
- Commits: Use clear, imperative titles (≤72 chars). Scope when helpful (e.g., "frontend: fix login redirect").
- PRs: Include purpose, linked issues, and screenshots/GIFs for UI. Ensure lints/compiles/tests are green. For Terraform PRs, attach the plan output.

## Security & Configuration Tips
- Never commit secrets.

## Project Specific Guidelines
- Read ./PROJECT.md and treat those guidelines as an appendix to these.

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
