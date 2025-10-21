#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook to enforce safety guardrails
# Blocks high-risk operations requiring explicit approval

# Read JSON input from stdin
INPUT=$(cat)

# Check if jq is available
if ! command -v jq &> /dev/null; then
  # Fallback: allow operation if jq not available (suppress output)
  echo '{"decision": "approve", "suppressOutput": true}' >&1
  exit 0
fi

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

# Function to block operation with message
block_operation() {
  local reason="$1"
  cat <<EOFJSON >&1
{
  "decision": "block",
  "reason": "${reason}"
}
EOFJSON
  exit 0
}

# Function to allow operation
allow_operation() {
  local suppress="${1:-false}"
  if [[ "$suppress" == "true" ]]; then
    echo '{"decision": "approve", "suppressOutput": true}' >&1
  else
    echo '{"decision": "approve"}' >&1
  fi
  exit 0
}

# Safety checks based on tool type
case "$TOOL_NAME" in
  "Bash")
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

    # Terraform apply - always block
    if [[ "$COMMAND" =~ terraform[[:space:]]+apply ]]; then
      block_operation "terraform apply requires explicit approval via /pe-apply command"
    fi

    # Kubectl apply/delete in non-kind contexts
    if [[ "$COMMAND" =~ kubectl[[:space:]]+(apply|delete) ]]; then
      if [[ ! "$COMMAND" =~ --context.*kind ]]; then
        block_operation "kubectl apply/delete in production requires explicit approval"
      fi
    fi

    # Recursive force delete
    if [[ "$COMMAND" =~ rm[[:space:]]+-rf ]]; then
      if [[ "$COMMAND" =~ /$ ]] || [[ "$COMMAND" =~ \*\* ]]; then
        block_operation "Recursive force delete with dangerous patterns requires approval"
      fi
    fi
    ;;
esac

# Default: allow operation (suppress output for routine approvals)
allow_operation "true"
