---
name: stability_checks
description: Verify main branch stability before development and before pushing code to remote.
inputs: { phase: required }  # phase: "preparation" or "pre-push"
outputs: { status: pass|fail, details: string }
dependencies: [ git, make/task/just ]
safety: Read-only on codebase; executes defined sanity/test targets.
steps:
  - Read PROJECT.md and look for a section called 'Stability Checks'.
  - If found, follow those directions for the given phase.
  - If not found, look for make/task/just targets with the word "sanity" and run the first one you find.
  - Report pass/fail status with details.
tooling:
  - git; make/task/just; test runners
---

# Stability Checks Skill

## Overview
This skill verifies that the codebase is in a stable state. It should be run:
1. **During preparation** - Before starting development work on main to ensure you're building on a stable foundation.
2. **Before pushing** - After completing implementation but before pushing to remote, to catch regressions early.

## Usage

### Phase: Preparation
Run at the start of any implementation workflow, after checking out and pulling main:
```
1. Read PROJECT.md
2. Look for a section called 'Stability Checks'
3. If found, follow those directions for the "preparation" phase
4. If not found, look for make/task/just targets with the word "sanity" and run the first one you find
5. If there are multiple build tools, run the first sanity target you find for each build tool
```

### Phase: Pre-Push
Run after implementation and testing, but before pushing to remote:
```
1. Read PROJECT.md
2. Look for a section called 'Stability Checks'
3. If found, follow those directions for the "pre-push" phase
4. If not found, run the same sanity targets as in preparation phase
5. This catches any regressions introduced by your changes
```

## Example PROJECT.md Section

A PROJECT.md file might define stability checks like this:

```markdown
## Stability Checks

### Preparation Phase
Run these before starting development:
- `make lint` - Verify linting passes
- `make test` - Run unit tests

### Pre-Push Phase
Run these before pushing code:
- `make lint` - Verify no new linting issues
- `make test` - Verify no test regressions
- `make build` - Verify build succeeds
```

## Fallback Behavior

If no PROJECT.md exists or no 'Stability Checks' section is found:
1. Search for Makefile, Taskfile.yml, justfile in the repository root
2. Look for targets containing "sanity" in their names
3. Execute the first matching target for each build tool found
4. Common patterns: `make sanity`, `task sanity`, `just sanity`

## Safety

- This skill is read-only with respect to the codebase
- It only executes existing, defined targets
- Failed checks should block further workflow progress
- Success/failure status should be clearly reported

## Integration with Agent Workflows

Agents should invoke this skill at two points:
1. **Step 1 (Preparation)**: After `git pull origin main`, before creating feature branch
2. **Step 5 (Pre-Push)**: After all tests pass, before `git push`

## Exit Criteria

- **Pass**: All stability checks complete successfully
- **Fail**: Any check fails; agent should investigate and fix before proceeding
