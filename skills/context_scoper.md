---
name: context_scoper
description: Minimize tokens by scoping context to relevant files and snippets.
inputs: { query: required, paths: optional }
outputs: { findings: list, snippets: md }
dependencies: [ ripgrep ]
safety: Read-only.
steps:
  - Locate relevant files with `rg` queries and globs.
  - Extract only needed lines/snippets.
  - Summarize structure; defer full content unless requested.
tooling:
  - commands: bin/context-scope
  - rg, sed, head, tail
---
