# Troubleshooting

## `make test` fails

Run the validator directly to see the repo-relative errors:

```bash
./test/validate-config.sh .
```

Common causes:

- `jq` is not installed
- a hook script is not executable
- `settings.json` is invalid JSON

## Hooks do not run

Check that the hook paths in `settings.json` match how you installed the repo.

This matters most for project-level installs because the default paths point to `~/.claude/hooks/...`.

## Safety hook is not blocking dangerous commands

Test it directly:

```bash
printf '%s\n' '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}' | hooks/pre_safety_check.sh
```

You should see JSON with `"decision": "block"`.

## Telemetry is not being written

The telemetry hook only writes entries when `CLAUDE_TELEMETRY=1` is set.

Quick test:

```bash
printf '%s\n' '{"tool_name":"Bash","session_id":"demo","cwd":"/tmp","tool_input":{"command":"echo ok"}}' | CLAUDE_TELEMETRY=1 hooks/post_telemetry.sh
```

Then check:

```bash
tail -n 5 ~/.claude/telemetry.jsonl
```

## GitHub helper scripts fail

Check:

- `gh` is installed
- `gh auth status` succeeds
- required environment variables such as `REPO` or `PR` are set

## Terraform helper scripts fail

Check:

- `terraform` is installed
- `DIR` points at a valid Terraform directory
- `WORKSPACE` is set when the script expects it

## Slash commands are missing

That is expected in the current repository state. This repository does not currently ship slash commands.
