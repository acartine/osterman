---
name: context_trim
event: context
description: Reduce context size by summarizing and scoping attachments.
policy:
  - Use rg to locate relevant files and include minimal snippets.
  - Summarize files >1,000 lines; avoid full pastes unless requested.
  - Prefer diffs and stat summaries over full patches.
telemetry: { tokens_estimate: true }
---

