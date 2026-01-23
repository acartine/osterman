**Purpose**
- Help you initiate prompts that maximize autonomy and minimize operator thrashing.

## The Recommended Workflow: Ship With Review

**For feature work, use the `ship_with_review` skill.** This is osterman's signature capability.

### The Ralph Wiggum Loop

Traditional AI development creates "thrashing"—operator repeatedly reviews and requests changes. The `ship_with_review` skill solves this by delegating review to Codex:

1. Agent implements the solution
2. **Codex** (not the operator) reviews the code
3. If `NEEDS_WORK`, agent iterates autonomously
4. Repeat until `APPROVED` or max iterations
5. CI verification and merge

**The operator only intervenes when automation hits its limits.**

### Usage

Simply ask the agent to ship a GitHub issue using the ship_with_review workflow:

```
Ship issue 123 using ship_with_review
```

Or reference the skill directly:

```
Use the ship_with_review skill to implement and merge issue #123
```

The agent handles implementation, review iteration, CI fixes, and merge.

## Commands

| Command | Use Case |
|---------|----------|
| `/tl triage` | Triage and prioritize open issues |
| `/tl ticket TYPE='bug' DESC='...'` | Create a GitHub issue |
| `/pe plan DIR=./infra` | Terraform plan (safe, autonomous) |
| `/pe apply DIR=./infra` | Terraform apply (requires approval) |
| `/test-health` | Test health report |
| `/dbg "error"` | Debug with scoped analysis |
| `/arch plan FEATURE="..."` | Architecture planning |

## Safety Cues

- Say "plan-only" for infra tasks
- Type "approval granted" to proceed with applies when prompted
- For production-impacting tasks, use `/pe` and confirm each step
