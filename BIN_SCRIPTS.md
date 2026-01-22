**Purpose**
- A small set of reusable shell commands that agents and humans can call directly. These prefer project targets (make/task/just) and default to safe behavior (dry-run where applicable).

**General Notes**
- All commands live in `bin/` and use `set -euo pipefail`.
- Many accept `REPO`, `PR`, `DIR`, `WORKSPACE`, or `DRY_RUN=1` env vars.
- DRY_RUN is enabled by default for risky actions (e.g., merges) and must be explicitly disabled: `DRY_RUN=0`.

**Commands**
- `bin/gh-issue-triage` — Summarize open issues with suggested priorities and owners.
  - Usage: `REPO=org/name bin/gh-issue-triage`
- `bin/gh-dependency-detect` — Detect dependencies between issues/PRs.
  - Usage: `REPO=org/name bin/gh-dependency-detect`
- `bin/gh-pr-review` — Fetch PR info and diff; print a compact review context.
  - Usage: `REPO=org/name PR=123 bin/gh-pr-review`
- `bin/gh-pr-merge` — Squash-merge a PR after checks; DRY_RUN=1 by default.
  - Usage: `REPO=org/name PR=123 DRY_RUN=0 bin/gh-pr-merge`
- `bin/tf-plan-only` — Run Terraform plan only; never apply.
  - Usage: `DIR=./infra WORKSPACE=staging bin/tf-plan-only`
- `bin/ci-fail-investigate` — Summarize failing jobs and likely causes.
  - Usage: `REPO=org/name bin/ci-fail-investigate`
- `bin/test-health-report` — Prefer project test target; summarize flakiness/slow tests if logs available.
  - Usage: `bin/test-health-report`
- `bin/context-scope` — Scope repository context with ripgrep and print compact findings.
  - Usage: `QUERY="auth middleware" bin/context-scope` or `PATTERN="src/**/*.ts" bin/context-scope`
- `bin/diff-summarize` — Summarize diffs with stats and focused patches.
  - Usage: `RANGE="origin/main...HEAD" bin/diff-summarize`

See hooks/pre_safety.md for safety policies and PROMPTING_GUIDE.md for examples.
