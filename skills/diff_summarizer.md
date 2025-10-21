---
name: diff_summarizer
description: Compress large diffs into structured summaries with hotspots.
inputs: { diff: required }
outputs: { summary: md, hotspots: list }
dependencies: [ git ]
safety: Read-only.
steps:
  - Group changes by module and type (add/modify/delete).
  - Highlight potential risk areas and cross-cutting concerns.
  - Provide targeted review focus list.
tooling:
  - commands: bin/diff-summarize
  - git diff --stat/--patch
---
