---
name: investigate
description: Evidence-gated debugging and investigation. Requires citing file:line references and actual output before proposing fixes.
---

# Investigate Skill

## Overview

Structured investigation workflow requiring concrete evidence before proposing any changes. Prevents premature fixes based on assumptions.

## Workflow

### Phase 1: Evidence Collection (NO code changes)

Gather concrete evidence using read-only tools:

1. **Reproduce the issue**: Run the failing command/test and capture exact output
2. **Trace the code path**: Use Grep/Glob/Read to find relevant code
3. **Cite references**: Every claim must include `file:line` references
4. **Capture runtime state**: Actual error messages, stack traces, log output

Deliverable: Evidence summary with:
- Exact error message(s)
- Code path: `file1.py:42` -> `file2.py:88` -> `file3.py:15`
- Root cause hypothesis supported by evidence

### Phase 2: Approval Gate

Present findings to user (or to self if autonomous):
- "Based on evidence at `file:line`, the root cause is X"
- "Proposed fix: change Y at `file:line`"
- Do NOT proceed to fix without confirming the root cause

### Phase 3: Targeted Fix

1. Make minimal changes to address the root cause
2. Verify the fix resolves the original issue
3. Run full verification suite

## Rules

- **Never** propose a fix without citing evidence
- **Never** make code changes during Phase 1
- **Never** guess at root causes -- trace the actual code
- If investigation is inconclusive, say so and suggest next steps
