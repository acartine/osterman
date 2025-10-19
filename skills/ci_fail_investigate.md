---
name: ci_fail_investigate
description: Summarize failing CI jobs and propose likely root causes and fixes.
inputs: { repo: required, pr_number: optional, branch: optional }
outputs: { failure_summary: markdown, fix_suggestions: list }
dependencies: [ gh CLI ]
safety: Read-only.
steps:
  - Fetch last failing jobs and logs.
  - Classify failures (lint/test/build/integration/secrets/quota).
  - Map to likely causes and remediation steps.
tooling:
  - commands: bin/ci-fail-investigate
  - Prefer project targets (make/task/just) if present; otherwise gh run list/view/logs and native runners
---
