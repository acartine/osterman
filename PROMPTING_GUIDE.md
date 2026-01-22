**Purpose**
- Help you initiate prompts that maximize autonomy, safety, and token efficiency.

**Pick the Right Agent**
- `tl`: Issue triage, dependency maps, ticket creation.
- `pe`: Production Engineering (hybrid) — Terraform plan reviews, CI/CD infra, containers/K8s; confirm-first for high-risk ops.
- `swe`: Implement complex features via standard branch workflow (Sonnet-powered).
- `jswe`: Implement simple tasks and bug fixes quickly (Haiku-powered, faster and cheaper).
- `test-engineer`: Improve tests, reduce flakiness, analyze test health.
- `code-debugger`: Diagnose runtime errors and unexpected behavior.
- `software-architect`: Integration plans, migrations, architecture decisions.
  (Merged into `pe` — use `pe` for confirm-first high-risk ops.)

**Slash Shortcuts (Recommended)**
- `/pe plan DIR=./infra WORKSPACE=staging` — Terraform plan-only summary (no apply)
- `/pe apply DIR=./infra WORKSPACE=prod` — Confirm-first flow for prod apply
- `/tl triage REPO=org/name` — Issue triage and dependency mapping
- `/tl ticket TYPE='bug' DESC='description'` — Create a new issue
- `/swe impl TASK="feature-x" SPEC=<link-or-notes>` — Implementation workflow for complex features
- `/jswe impl TASK="fix-bug" SPEC="add null check"` — Fast implementation for simple tasks
- `/test health` — Test health report
- `/dbg failing test LoginFlow` — Debugger requests stack/repro and proposes fixes
- `/arch plan FEATURE="realtime notifications"` — Architecture plan

**Prompt Recipes (Copy/Paste)**
- Triage and plan
  - "Agent: tl. Goal: Triage open issues for repo X, produce priority list and dependency graph for the top 10. Keep tokens low; use context_scoper."
- Terraform plan-only
  - "Agent: pe. Run tf_plan_only in ./infra env 'staging' (bin/tf-plan-only). Summarize adds/changes/destroys, highlight IAM/network/cost risks. Do not apply."
- Debugging
  - "Agent: code-debugger. Context: failing unit test Y. Expected vs actual, stack trace here: ... Scope relevant files and propose fixes + verification steps."
- Implementation (complex features)
  - "Agent: swe. Spec: implement feature X per doc link. Follow ship_with_review (bin/impl-worktree-workflow). Open DRAFT PR and iterate until green."
- Implementation (simple tasks)
  - "Agent: jswe. Spec: fix bug Y by adding validation. Follow ship_with_review. Open DRAFT PR and iterate until green. Use Haiku for speed."
- Test health
  - "Agent: test-engineer. Analyze last 10 CI runs. Produce test health report: flakiest tests, slowest suites, top fixes. You may use bin/test-health-report."
- Architecture
  - "Agent: software-architect. Produce a phased integration plan for feature X with 3 independent engineer tracks per phase."
- Non-autonomous high-risk work
  - "Agent: pe. Task: plan-and-apply Terraform for service X in prod. Proceed in Clarify → Propose → Confirm → Execute steps only."

**Token Efficiency Tips**
- Always specify the agent name and goal in one sentence.
- Provide minimal context references (paths, PR #, test names) and let the agent use `context_scoper`.
- Ask for summaries first; expand on a specific section when needed.
- Prefer plan-only and diffs/stat over full file dumps.

**Safety Cues**
- Say "plan-only" for infra tasks; explicitly type "approval granted" to proceed with applies when prompted.
- For production-impacting tasks, always select `pe` and confirm each step.

**Examples of Good vs. Better**
- Good: "Triage issues."
- Better: "Agent: tl. Goal: Triage open issues for repo X, produce priority list and dependency graph."
