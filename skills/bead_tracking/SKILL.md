---
name: bead_tracking
description: Manage the bead lifecycle from discovery through implementation to close. Use when working with beads issues for task tracking.
---

# Bead Tracking Skill

## Overview

Manages the complete lifecycle of beads (local issue tracking) from finding work through implementation to closure. Ensures consistent tracking discipline across sessions.

## Prerequisites

- `bd` CLI must be available (`command -v bd`)
- If `bd` is not available, skip bead operations and proceed with work normally

## Workflow

### Phase 1: Find Work

```bash
bd ready                           # Show issues with no blockers
bd list --status=open              # All open issues
bd list --status=open | grep TAG   # Filter by tag/label
```

Choose an issue to work on. Review details:

```bash
bd show <id>                       # Full details, dependencies, notes
```

### Phase 2: Claim and Start

```bash
bd update <id> --status=in_progress   # MUST do this BEFORE any code changes
```

Verify you're on the correct branch (create feature branch if needed):

```bash
git branch --show-current
git checkout -b feature/<descriptive-name> main   # if needed
```

### Phase 3: Implement

1. Read the bead's notes for requirements and context
2. Implement the changes following project verification rules:
   - Python/model changes: `make model-sanity`
   - Go changes: `task compile && task test`
3. Do NOT skip verification

### Phase 4: Commit and PR

```bash
git add <changed-files>
git commit -m "<type>(<scope>): <description>

Bead: <bead-id>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push -u origin <branch>
gh pr create --title "<title>" --body "..."
```

### Phase 5: Close

```bash
bd close <id> --reason="Implemented in PR #<number>"
```

For multiple beads in one PR:

```bash
bd close <id1> <id2> <id3> --reason="Implemented in PR #<number>"
```

### Phase 6: Handoff (if stopping mid-work)

Update bead notes with a handoff capsule:

```bash
bd update <id> --notes="HANDOFF:
- What changed: <files/edits>
- What remains: <2-6 bullets>
- Verification: <make model-sanity | task compile && task test>"
```

## Batch Execution

When instructed to "execute beads" with filters:

1. `bd ready` (with filters) to get matching list
2. Group by target file to avoid merge conflicts
3. Launch parallel subagents for independent groups
4. Each agent: claim -> implement -> verify -> commit -> PR -> close
5. Do NOT ask for scope confirmation -- the filter IS the scope

## Rules

- **Always** mark in_progress before starting work
- **Always** close beads with a reason referencing the PR
- **Never** skip bead tracking when `bd` is available
- **Never** use `bd init` or `bd edit` (opens interactive editor)
- Beads are local-only -- do not commit beads data to git
