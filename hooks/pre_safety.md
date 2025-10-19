---
name: pre_safety
event: pre
description: Intercept risky or destructive actions and require explicit approval.
policy:
  - Block terraform/kubectl apply in non-kind contexts without approval.
  - Block prod DB changes, secret rotations, DNS/SSL/CDN changes.
  - Escalate to Pair Programmer for high-risk operations.
telemetry: { tokens_estimate: true, action_log: true }
---

