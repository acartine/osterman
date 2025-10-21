---
name: test_health_report
description: Identify flakiest and slowest tests, propose quick wins.
inputs: { repo: optional, recent_runs: optional }
outputs: { health_report: markdown, top_offenders: list }
dependencies: [ local test runner, gh CLI optional ]
safety: Read-only.
steps:
  - Parse recent CI results or local runs for failures and duration.
  - Highlight flakiness patterns and performance hotspots.
  - Recommend fixes (mock/time controls, parallelism, data builders).
tooling:
  - commands: bin/test-health-report
  - Prefer project targets (make/task/just) if present; otherwise use jest/pytest/go test flags; gh run logs
---
