**Purpose**
- Help you prompt against the repo as it exists now.

## Working Style

This config is modular. There is no single built-in "ship the issue end to end" workflow anymore.

The most reliable prompts do one of these:

- pick an agent for role context
- name a specific skill for a narrow workflow
- say the exact outcome you want verified

## Good Prompt Patterns

For implementation work:

```text
Use the swe agent to implement issue #123. Start with pull_main, run stability_checks, keep the change small, and show me verification before you stop.
```

For documentation work:

```text
Use the documentation skill to update the install docs after the hook changes. Remove stale claims and keep the examples runnable.
```

For repo orientation:

```text
Use orientation to map this repository and point me to the files that handle Terraform safety checks.
```

For investigation first:

```text
Use investigate to find why the CI job is failing. Do not propose a fix until you have concrete evidence.
```

For Terraform planning:

```text
Use the pe agent with tf_plan_only for ./infra workspace staging and summarize the blast radius.
```

For repo documentation generation:

```text
Use map-repo to generate or refresh architecture-oriented docs for this repository.
```

## What To Say Explicitly

Be explicit about:

- the repository or directory to work in
- whether you want analysis only or code changes
- what verification you expect
- whether a PR, branch, or commit is needed

## Safety Cues

- Say `plan only` for infra tasks when you do not want any apply path explored.
- Say `investigate first` when you want evidence before implementation.
- Say `documentation only` when code changes are out of scope.

## Current Capabilities To Reference

Agents:

- `pe`
- `swe`
- `doc`

Skills:

- `orientation`
- `documentation`
- `investigate`
- `pull_main`
- `rebase`
- `stability_checks`
- `tf_plan_only`
- `iac`
- `infra_change_review`
- `map-repo`
- `enforce-sourcecode-size`

Helper scripts:

- `bin/gh-pr-review`
- `bin/gh-pr-merge`
- `bin/gh-issue-triage`
- `bin/tf-plan-only`
- `bin/ci-fail-investigate`
