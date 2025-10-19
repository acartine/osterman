---
name: gh_event_heuristics
event: pre
description: Simulate periodic checks for open PRs/issues and act opportunistically.
policy:
  - On invocation, list open PRs/issues and prioritize top N.
  - Skip drafts; focus on items with recent activity.
  - Avoid noisy churn; limit comments to meaningful updates.
telemetry: { action_log: true }
---

