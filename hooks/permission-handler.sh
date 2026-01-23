#!/bin/bash
# PermissionRequest hook for Bash commands
# Handles permission requests with conditional allow/deny logic
#
# Input format:
# {
#   "session_id": "abc123",
#   "transcript_path": "/path/to/transcript.jsonl",
#   "cwd": "/path/to/cwd",
#   "permission_mode": "default",
#   "hook_event_name": "PermissionRequest",
#   "tool_name": "Bash",
#   "tool_input": {
#     "command": "...",
#     "description": "..."
#   },
#   "tool_use_id": "toolu_01ABC123..."
# }

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# 1) If command contains 'venv' -> DENY (use poetry instead)
if echo "$command" | grep -qi 'venv'; then
  cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "deny", "message": "This is a poetry project, use poetry or a make target instead"}}}
EOF
  exit 0
fi

# 2) If command contains 'python3' or 'PYTHONPATH' -> ALLOW
if echo "$command" | grep -qi -E '(python3|PYTHONPATH)'; then
  cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "allow"}}}
EOF
  exit 0
fi

# 3) Default: no output means fall through to normal permission prompt
# (Don't deny everything - only deny specific patterns like venv)
exit 0
