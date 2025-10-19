---
name: command_router
event: pre
description: Parse leading '/' shortcuts in user messages and dispatch to the appropriate agent + skill with sensible defaults.
policy:
  - Recognize messages starting with '/'.
  - Supported commands and mappings:
    - '/pe plan DIR=<path> [WORKSPACE=<name>]' → agent 'pe' + skill 'tf_plan_only' (never apply)
    - '/pe apply DIR=<path> [WORKSPACE=<name>]' → agent 'pe' confirm-first flow; summarize plan and require explicit approval before any apply
    - '/tl review REPO=<org/name> PR=<num>' → agent 'tl' + skills 'gh_pr_review' and optional 'gh_pr_merge'
    - '/tl triage REPO=<org/name>' → agent 'tl' + skills 'gh_issue_triage','gh_dependency_detect'
    - '/swe impl TASK="<desc>" [SPEC=<url-or-notes>]' → agent 'swe' + skill 'impl_branch_workflow'
    - '/test health' → agent 'test-engineer' + skill 'test_health_report'
    - '/dbg <desc>' → agent 'code-debugger' (request stack trace, repro steps, and scope context)
    - '/arch plan FEATURE="<desc>"' → agent 'software-architect' + skill 'arch_integration_plan'
  - Accept shorthand '#<num>' for PR where unambiguous in current repo context.
telemetry: { action_log: true }
---
