---
name: post_telemetry
event: post
description: Emit action summary, token estimate, and suggested next step.
policy:
  - Log actions taken and pending approvals required.
  - Provide delta token estimate for this run.
  - Suggest the next best action for the agent.
telemetry: { tokens_estimate: true, action_log: true }
---

