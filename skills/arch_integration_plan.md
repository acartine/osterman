---
name: arch_integration_plan
description: Produce phased integration plans with independent tracks and clear contracts.
inputs: { feature: required, context: optional }
outputs: { executive_summary: md, phases: md, contracts: md }
dependencies: [ none ]
safety: Planning only.
steps:
  - Assess current architecture and impact zones.
  - Define integration points, interfaces, and data flows.
  - Create phased plan with 3 independent engineer tracks per phase.
  - Include testing, rollout, and rollback strategies.
tooling:
  - Textual diagrams and structured markdown
---

