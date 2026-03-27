---
name: map-repo
description: Generate agent-friendly ARCHITECTURE.md index and per-directory README.md files for any codebase.
inputs: { directories: optional }
outputs: { architecture: markdown, readmes: markdown }
dependencies: [ git ]
safety: Non-destructive; creates or updates documentation files only.
steps:
  - Explore the full repository structure using Explore agents to understand every directory's purpose, key files, types, and functions.
  - Identify which directories warrant a README (skip test/fixture dirs unless asked, skip trivially small or self-evident dirs).
  - If the user specified directories, use those. Otherwise propose a list and confirm.
  - Write a concise README.md in each selected directory covering purpose, key files, key types/functions, and how it fits in the broader system.
  - Write a top-level ARCHITECTURE.md that serves as an index with a directory map table linking to each README, a data/control flow summary, key entry points, and build system notes.
  - Review all files for accuracy against the actual source before finishing.
tooling:
  - commands: /map-repo
  - Explore agents for codebase discovery; standard file tools for writing
---

## Style Guidelines

- Each README: 10-30 lines. Lead with purpose, then contents.
- Reference key files, types, and functions by name so agents can grep for them.
- No badges, no emojis, no boilerplate filler.
- ARCHITECTURE.md should let an agent understand the repo's purpose, structure, and data flow in under 60 seconds.
- Use tables for directory maps. Use code blocks for flow diagrams.
- Keep descriptions factual and current — don't document aspirational state.

## ARCHITECTURE.md Template

```markdown
# <Project> Architecture

<One-sentence purpose.>

## Data/Control Flow

<Short flow diagram or description.>

## Directory Map

| Path | Purpose |
|------|---------|
| [`path/`](path/README.md) | One-line description |

## Key Entry Points

- **<Role>**: `file.py` — `function()`

## Build System

<Package manager, key targets, how to run.>
```

## Per-Directory README Template

```markdown
# <directory name>

<One-sentence purpose.>

## Key Files

- **`file.py`** — what it does

## Key Types

- `TypeName` — what it represents

## Key Functions

- `function_name()` — what it does
```
