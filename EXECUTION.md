**Objectives**
- Make subagents autonomous by default with safe guardrails.
- Consolidate infra + pair-programmer into a single Production Engineering (pe) hybrid agent.
- Optimize token usage via lean prompts, shared skills, and hooks.

**Assumptions**
- Current structure: `CLAUDE.md`, `agents/*.md` exist; no `skills/` or `hooks/` yet.
- GitHub CLI (`gh`) and common CLIs are available when needed by agents.
- You prefer minimal, composable prompts that reference shared reusable skills.

**Current State Summary**
- `agents/tl.md` already describes autonomous PR review and merge flow but mixes policy and process into the agent prompt.
- `agents/cloud-infra-devops.md` is comprehensive but lacks explicit guardrails for apply/production ops.
- `agents/code-implementer.md`, `agents/test-engineer.md`, `agents/code-debugger.md`, `agents/software-architect.md` repeat patterns that can be factored into shared skills to reduce tokens.
- `CLAUDE.md` is general repo/flow guidance; it can serve as a central reference instead of repeating details in each agent.

**Plan Overview**
- Phase 1: Baseline conventions and autonomy policy
- Phase 2: Introduce skills library (reusable steps, token-thrifty)
- Phase 3: Add guardrail hooks (safety + context + telemetry)
- Phase 4: Refactor agents to be thin, skill-composed
- Phase 5: Add Production Engineering hybrid agent (pe)
- Phase 6: Rollout + validation + continuous refinement

**Phase 1 — Baseline Conventions & Autonomy Policy**
- Add `CLAUDE.md` sections for autonomy and safety once, referenced by all agents.
  - Default: agents run autonomously for their domain.
  - Require explicit approval for: `terraform apply`, `kubectl apply/delete` against non-kind contexts, prod DB migrations, destructive ops, secret/key rotations, DNS/SSL changes, cost-impacting infra.
  - Require approval when: workflows fail, PR checks red, permissions insufficient, or changes exceed defined risk thresholds.
- Normalize agent front matter to include:
  - `autonomy: true|false` (default true; `pe` enforces confirm-first for high-risk)
  - `skills: [ ... ]` list of skill names
  - `hooks: [ pre_safety, context_trim, post_telemetry ]` as needed
  - `scope: [ repo, github, cloud, data ]` for quick auditability
- Add a concise “When To Use” and “What I Do Autonomously” section in each agent, deferring details to skills.

**Phase 2 — Skills Library (reusable, composable)**
- Create `skills/` folder; each skill is a small, focused capability described in a short MD file with front matter:
  - `name`, `description`, `inputs`, `outputs`, `dependencies`, `safety`, `steps`, `tooling`
- Core skill packs:
  - GitHub Management
    - `skills/gh_issue_triage.md`: fetch issues, label, priority, owner recommendation, due-date suggestions.
    - `skills/gh_dependency_detect.md`: detect issue/PR dependencies via links/keywords/PR checks.
    - `skills/gh_pr_review.md`: fetch diff, run static checks, summarize, propose changes.
    - `skills/gh_pr_merge.md`: verify green checks, squash merge, fallback to approve + comment if rebase required.
  - PR Quality & CI
    - `skills/ci_fail_investigate.md`: pull failing jobs, summarize root cause, suggest fix.
    - `skills/test_health_report.md`: flaky/slow tests summary with top offenders.
  - Infra Guardrails
    - `skills/tf_plan_only.md`: always produce `terraform plan`, summarize risk; block apply unless approved.
    - `skills/infra_change_review.md`: checklist review for IAM, networking, cost, blast-radius.
  - Implementation & Architecture
    - `skills/impl_branch_workflow.md`: standard branch/PR flow, reusing `CLAUDE.md` rules.
    - `skills/arch_integration_plan.md`: skeleton for phased integration output.
  - Token Efficiency
    - `skills/context_scoper.md`: resolve only relevant files with `rg`, extract snippets, summarize.
    - `skills/diff_summarizer.md`: compress large diffs into sectioned summaries.

**Phase 3 — Hooks (cross-cutting safety, context, telemetry)**
- Create `hooks/` folder with short MD specs (one page each) that agents reference in front matter:
- `hooks/pre_safety.md`: intercept destructive commands, require approval and enforce confirm-first flow in `pe`.
  - `hooks/context_trim.md`: auto-summarize large files and limit attachment sizes; prefer `rg`-scoped snippets.
  - `hooks/post_telemetry.md`: emit action summary, token estimates, and next best action.
  - `hooks/gh_event_heuristics.md`: if no webhook support, simulate periodic checks when agent runs (e.g., list open PRs/issues and act).

**Phase 4 — Refactor Agents To Use Skills**
- Update each agent to a thin prompt referencing skills and hooks.
- Suggested skill composition:
  - `agents/tl.md` → skills: `gh_issue_triage`, `gh_dependency_detect`, `gh_pr_review`, `gh_pr_merge`, `ci_fail_investigate`; hooks: `pre_safety`, `context_trim`, `post_telemetry`; `autonomy: true`.
  - `agents/pe.md` → skills: `tf_plan_only`, `infra_change_review`, `ci_fail_investigate`; hooks: `pre_safety` (mandatory), `context_trim`, `post_telemetry`; `autonomy: true` with confirm-first for high-risk.
  - `agents/swe.md` → skills: `impl_branch_workflow`, `diff_summarizer`, `context_scoper`; hooks: `context_trim`, `post_telemetry`; `autonomy: true`.
  - `agents/test-engineer.md` → skills: `test_health_report`, `diff_summarizer`, `context_scoper`; hooks: `context_trim`; `autonomy: true`.
  - `agents/code-debugger.md` → skills: `context_scoper`; hooks: `context_trim`; `autonomy: true`.
  - `agents/software-architect.md` → skills: `arch_integration_plan`, `context_scoper`; hooks: `post_telemetry`; `autonomy: true`.

**Phase 5 — Add Production Engineering (pe)**
- Add `agents/pe.md` as a hybrid agent:
  - Safe Autonomy for plan-only/analysis; Confirm-First for high-risk actions.
  - Enforce guardrails via `pre_safety`; never applies infra or destructive ops without explicit approval.
  - Skills: `tf_plan_only`, `infra_change_review`, `ci_fail_investigate`, `context_scoper`, `diff_summarizer`.

**Phase 6 — Rollout & Validation**
- Dry-run each agent against a sample repo:
  - Team Lead: triage open issues, propose dependency map, review latest 1–2 PRs, produce merge results or feedback.
  - Infra DevOps: run `tf_plan_only`, produce risk summary, request approval if apply needed.
  - Implementer + Test Engineer: implement trivial change + focused tests using branch workflow skill.
- Verify hooks fire as expected; confirm token telemetry and context trimming occur.
- Adjust skill scopes to reduce context pull where overbroad.

**Token Optimization Tactics**
- Keep agent files lean: 1–2 paragraphs + skill list + hooks; remove repeated checklists duplicated across agents.
- Centralize shared policies in `CLAUDE.md` and refer to sections by name (don’t inline them in agents).
- Prefer skills for any repeated sequence (PR review steps, branch flow, CI diagnosis, terraform plan review).
- Use `context_scoper` skill before heavy operations; rely on `rg` over full tree reads.
- Summarize large diffs/files with `diff_summarizer` instead of pasting raw content.
- Encourage “progressive disclosure”: start with summaries, only expand sections on demand.

**Editing Checklist (Concrete Steps)**
1) `CLAUDE.md`: add sections
   - Autonomy Policy (default autonomous, exceptions list).
   - Safety Guardrails (high-risk ops require approval; examples and commands).
   - Token Usage Policy (context scoping, summarization, attachment limits).
2) Create `skills/` with initial files:
   - `gh_issue_triage.md`, `gh_dependency_detect.md`, `gh_pr_review.md`, `gh_pr_merge.md`.
   - `ci_fail_investigate.md`, `test_health_report.md`.
   - `tf_plan_only.md`, `infra_change_review.md`.
   - `context_scoper.md`, `diff_summarizer.md`, `impl_branch_workflow.md`, `arch_integration_plan.md`.
3) Create `hooks/` with:
   - `pre_safety.md`, `context_trim.md`, `post_telemetry.md`, `gh_event_heuristics.md`.
4) Add `agents/pe.md` (hybrid; confirm-first for high-risk, autonomous for safe analyses).
5) Refactor existing agents to:
   - Add `autonomy: true`, `skills: [...]`, `hooks: [...]`, and a concise “What I do autonomously”.
   - Replace long procedural text with references to skills and `CLAUDE.md` sections.
6) Smoke test via small tasks per agent; check that hooks/skills keep prompts short and actions correct.

**Templates (Copy/Paste Skeletons)**
- Agent front matter minimal template:
  ---
  name: example-agent
  description: One-sentence purpose and when to use.
  model: sonnet
  color: blue
  autonomy: true
  skills: [ skill_a, skill_b ]
  hooks: [ pre_safety, context_trim, post_telemetry ]
  scope: [ repo ]
  ---

- Skill template (`skills/example.md`):
  ---
  name: example
  description: What the skill does in 1–2 lines.
  inputs: { required: [x, y], optional: [z] }
  outputs: { summary, artifacts? }
  dependencies: [ tools/cli ]
  safety: Approval required if [conditions]
  steps:
    - Step 1
    - Step 2
  tooling:
    - Commands or APIs used
  ---

- Hook template (`hooks/example.md`):
  ---
  name: example
  event: pre|post|context
  description: What the hook enforces
  policy:
    - Block or warn on [conditions]
    - Trim/summarize context to [limits]
  telemetry: { tokens_estimate: true, action_log: true }
  ---

**Governance & Safety**
- Keep a short `RISK_REGISTER.md` noting categories that force confirm-first flow in `pe`.
- Add a `CHANGELOG.md` entry pattern for agent/skill changes.
- Perform quarterly review to prune skills, merge duplicates, and tighten scopes.

**Quick Guide — Subagents vs. Hooks vs. Skills**
- Subagents: role-specialized flows or multi-step strategies (Team Lead, Production Engineering, Architect).
- Skills: reusable atomic capabilities invoked by agents (PR review, plan-only, triage, context scoping).
- Hooks: cross-cutting guardrails and ergonomics (safety gating, context trimming, telemetry).

**Success Criteria**
- Agents act autonomously for routine domain work; risky actions always pause for approval.
- `pe` switches to confirm-first for high-impact tasks.
- Prompt size drops due to skills + hooks; token spend decreases while output quality stays high.
