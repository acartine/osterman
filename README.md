# Osterman Claude Configuration

Production-ready Claude Code configuration for autonomous software development workflows.

## What is this?

The `osterman` .claude configuration provides autonomous agent workflows for professional software development. It implements a secure, efficient approach to taking GitHub issues from triage to merged PR using Claude Code CLI.

## Why is it called `osterman`?

Before he was Dr. Manhattan, he was Jon Osterman. We hope someday to be Dr. Manhattan.

## The Signature Workflow: Ship With Review

The crown jewel of osterman is the **`ship_with_review` skill**—an end-to-end autonomous workflow that takes a GitHub issue from triage to merged PR with minimal operator intervention.

### The Problem: Operator Thrashing

Traditional AI-assisted development creates a frustrating loop:
1. Agent implements code
2. Operator reviews and requests changes
3. Agent makes changes
4. Operator reviews again...
5. Repeat until operator is exhausted

This "thrashing" defeats the purpose of autonomous agents—the human becomes the bottleneck.

### The Solution: The Ralph Wiggum Loop

Osterman solves this with **delegated third-party review**. Instead of the operator reviewing code, we delegate review to another AI agent (Codex). The workflow:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Implement  │────►│ Codex       │────►│ APPROVED?   │
│  Solution   │     │ Review      │     │             │
└─────────────┘     └─────────────┘     └──────┬──────┘
       ▲                                       │
       │            NEEDS_WORK                 │
       └───────────────────────────────────────┘
```

We call this the **"Ralph Wiggum Loop"**—after enough automated review cycles, even Ralph could approve it. The agent iterates autonomously until the code passes muster, then proceeds to CI verification and merge.

**Benefits:**
- **No operator thrashing**: Kick off the workflow and check back when it's done
- **Consistent review quality**: Every PR gets the same thorough review
- **Faster iteration**: Agent can address feedback immediately without waiting for human availability
- **Operator as escalation path**: Humans only intervene when the automation hits its limits (max iterations, timeouts)

### Quick Start

Simply ask the agent to ship a GitHub issue:

```
Ship issue 123 using ship_with_review
```

Or:

```
Use the ship_with_review skill to implement and merge issue #123
```

This skill will:
1. Read and analyze the GitHub issue
2. Create a feature branch in a worktree
3. Implement the solution
4. Create a PR and trigger Codex review
5. Iterate on NEEDS_WORK feedback (up to 5 times)
6. Poll for green CI and fix failures (up to 3 times)
7. Squash merge and clean up

## Other Commands

| Command | Description |
|---------|-------------|
| `/tl triage` | Triage open issues, map dependencies |
| `/tl ticket TYPE='bug' DESC='...'` | Create a GitHub issue |
| `/pe plan DIR=./infra` | Terraform plan with risk summary |
| `/pe apply DIR=./infra` | Terraform apply (requires approval) |
| `/test-health` | Analyze test suite for flaky/slow tests |
| `/dbg "error message"` | Debug with scoped analysis |
| `/arch plan FEATURE="..."` | Architecture planning |

## Installation

```bash
# Backup existing config and clone
mv ~/.claude ~/.claude.backup
git clone https://github.com/YOUR_USERNAME/osterman.git ~/.claude

# Verify
cd ~/.claude && make test
```

## Safety Hooks

- **`pre_safety_check.sh`** - Blocks dangerous operations (terraform apply, kubectl delete, etc.)
- **`post_telemetry.sh`** - Logs tool usage for audit

## Recommended Tooling

This configuration recommends **[shemcp](https://github.com/acartine/shemcp)** for enhanced bash command execution. Remove the shemcp section from `CLAUDE.md` if not using it.

---

Built with Claude Code CLI for autonomous, safe, and efficient software development workflows.
