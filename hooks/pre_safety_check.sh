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

    # Git push to main/master - block
    if [[ "$COMMAND" =~ git[[:space:]]+(push|push[[:space:]]) ]]; then
      # Block if command explicitly targets main/master remote branch
      if [[ "$COMMAND" =~ (origin|upstream)[[:space:]]+(main|master) ]]; then
        block_operation "Pushing to main/master is prohibited. Create a feature branch first: git checkout -b <branch-name>"
      fi
      # Block if currently on main/master (implicit push)
      CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
      if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
        block_operation "You are on '$CURRENT_BRANCH'. Pushing directly to main/master is prohibited. Create a feature branch first: git checkout -b <branch-name>"
      fi
    fi

    ;;
  "mcp__shemcp__shell_exec")
    CMD=$(echo "$TOOL_INPUT" | jq -r '.cmd // ""')
    ARGS=$(echo "$TOOL_INPUT" | jq -r '(.args // []) | join(" ")')
    FULL_CMD="$CMD $ARGS"

    # Git push to main/master - block
    if [[ "$CMD" == "git" ]] && [[ "$ARGS" =~ ^push ]]; then
      # Block if args explicitly target main/master remote branch
      if [[ "$ARGS" =~ (origin|upstream)[[:space:]]+(main|master) ]]; then
        block_operation "Pushing to main/master is prohibited. Create a feature branch first: git checkout -b <branch-name>"
      fi
      # Block if currently on main/master (implicit push)
      CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
      if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
        block_operation "You are on '$CURRENT_BRANCH'. Pushing directly to main/master is prohibited. Create a feature branch first: git checkout -b <branch-name>"
      fi
    fi

    ;;
esac

# Default: allow operation (suppress output for routine approvals)
allow_operation "true"
