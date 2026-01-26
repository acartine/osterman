---
name: tf_plan_only
description: Execute Terraform plan and produce a risk summary; never apply.
inputs: { dir: required, workspace: optional }
outputs: { plan_summary: markdown, risk_assessment: markdown }
dependencies: [ terraform, make/task targets if present ]
safety: Blocks apply; escalate to Pair Programmer for applies.
steps:
  - Initialize and select workspace if needed.
  - Run terraform plan using project targets when available.
  - Summarize adds/changes/destroys; flag unintended destroys.
  - List IAM/networking/cost-sensitive resources.
tooling:
  - commands: bin/tf-plan-only
  - terraform init/plan; make terraform/plan targets
---
