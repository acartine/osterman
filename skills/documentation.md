---
name: documentation
description: Create clear, well-placed user documentation following project patterns.
inputs: { feature: required }
outputs: { documentation: markdown, placement: suggested }
dependencies: [ git ]
safety: Non-destructive; creates or updates documentation files only.
steps:
  - Explore existing documentation structure and patterns.
  - Find related code implementation using grep/glob.
  - Analyze documentation style and format conventions.
  - Determine appropriate placement for new docs.
  - Create user-focused documentation with examples.
  - Suggest integration with existing docs (TOC, links).
tooling:
  - commands: /doc
  - Standard file search and editing tools
---
