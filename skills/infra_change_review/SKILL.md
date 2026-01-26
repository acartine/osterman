---
name: infra_change_review
description: Checklist-based review for infra diffs (IAM, networking, cost, blast radius).
inputs: { plan_or_diff: required }
outputs: { review_report: markdown, risk_level: string }
dependencies: [ terraform/kubectl/helm as applicable ]
safety: Non-destructive; flags risky changes and requires approval.
steps:
  - Parse plan/diff and categorize resources.
  - Evaluate IAM privilege changes, public exposure, egress/ingress.
  - Estimate potential cost changes and state drift risk.
  - Propose mitigations and phased rollout.
tooling:
  - terraform plan output, kubectl diff, helm template
---

