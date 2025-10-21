#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook for operation telemetry
# Logs tool usage for analysis and audit

INPUT=$(cat)

# Check if telemetry is enabled
if [[ -z "${CLAUDE_TELEMETRY:-}" ]]; then
  # Telemetry disabled, just continue
  echo '{"decision": "approve", "suppressOutput": true}' >&1
  exit 0
fi

# Extract information (with fallbacks if jq unavailable)
if command -v jq &> /dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
  CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
  TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

  # Extract specific fields for common tools
  if [[ "$TOOL_NAME" == "Bash" ]]; then
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // "unknown"')
    DESCRIPTION=$(echo "$TOOL_INPUT" | jq -r '.description // ""')
  else
    COMMAND="N/A"
    DESCRIPTION=""
  fi
else
  TOOL_NAME="unknown"
  SESSION_ID="unknown"
  CWD="unknown"
  TOOL_INPUT="{}"
  COMMAND="unknown"
  DESCRIPTION=""
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Determine telemetry file location
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  TELEMETRY_FILE="${CLAUDE_PROJECT_DIR}/.claude/telemetry.jsonl"
else
  TELEMETRY_FILE="${HOME}/.claude/telemetry.jsonl"
fi

# Create directory if needed
mkdir -p "$(dirname "$TELEMETRY_FILE")" 2>/dev/null || true

# Append telemetry entry
if command -v jq &> /dev/null; then
  jq -n \
    --arg ts "$TIMESTAMP" \
    --arg session "$SESSION_ID" \
    --arg tool "$TOOL_NAME" \
    --arg cwd "$CWD" \
    --arg cmd "$COMMAND" \
    --arg desc "$DESCRIPTION" \
    '{timestamp: $ts, session: $session, tool: $tool, cwd: $cwd, command: $cmd, description: $desc}' \
    >> "$TELEMETRY_FILE" 2>/dev/null || true
else
  # Fallback without jq
  echo "{\"timestamp\":\"$TIMESTAMP\",\"session\":\"$SESSION_ID\",\"tool\":\"$TOOL_NAME\",\"cwd\":\"$CWD\",\"command\":\"$COMMAND\",\"description\":\"$DESCRIPTION\"}" \
    >> "$TELEMETRY_FILE" 2>/dev/null || true
fi

# Always approve and continue, suppress output
echo '{"decision": "approve", "suppressOutput": true}' >&1
exit 0
