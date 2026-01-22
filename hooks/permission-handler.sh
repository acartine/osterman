#!/bin/bash
# Notification hook for permission_prompt
# Handles permission requests with conditional allow/deny logic
#
# Input format:
# {
#   "session_id": "abc123",
#   "transcript_path": "/path/to/transcript.jsonl",
#   "cwd": "/path/to/cwd",
#   "permission_mode": "default",
#   "hook_event_name": "Notification",
#   "message": "Claude needs your permission to use Bash",
#   "notification_type": "permission_prompt"
# }

input=$(cat)
message=$(echo "$input" | jq -r '.message // empty')

# 1) If message contains 'venv' -> DENY (use poetry instead)
if echo "$message" | grep -qi 'venv'; then
  cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "deny", "message": "This is a poetry project, use poetry or a make target instead"}}}
EOF
  exit 0
fi

# 2) If message contains 'python3' or 'PYTHONPATH' -> ALLOW
if echo "$message" | grep -qi -E '(python3|PYTHONPATH)'; then
  cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "allow"}}}
EOF
  exit 0
fi

# 3) Otherwise -> suggest alternatives via deny with helpful message
cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "deny", "message": "Try using mcp__shemcp__shell_exec for better sandboxing, or check for a Makefile/Taskfile target that solves the same problem."}}}
EOF
exit 0
