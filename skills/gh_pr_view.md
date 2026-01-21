---
name: gh_pr_view
description: View PR state using GitHub CLI with structured JSON output
inputs: { pr_number: required, repo: optional }
outputs: { state: string, mergedAt: string, mergedBy: object }
dependencies: [ gh CLI ]
safety: Read-only operation; no modifications to PR state.
steps:
  - Accept PR number and optional repo parameter
  - Execute gh pr view with JSON output
  - Return structured data with state, mergedAt, and mergedBy
  - Handle errors gracefully (PR not found, permissions, etc.)
tooling:
  - gh pr view <num> --json state,mergedAt,mergedBy [--repo org/name]
---

# GitHub PR View Skill

This skill provides a standardized way to check PR states across all agents using the GitHub CLI.

## Usage

The skill accepts the following parameters:
- `pr_number`: The pull request number (required)
- `repo`: Optional repository in org/name format (defaults to current repository)

## Output Format

Returns JSON with the following fields:
- `state`: PR state (OPEN, CLOSED, MERGED)
- `mergedAt`: ISO 8601 timestamp when PR was merged (null if not merged)
- `mergedBy`: Object containing merge author info (null if not merged)
  - `login`: GitHub username who merged the PR

## Example Usage

### Basic usage (current repository):
```bash
gh pr view 5 --json state,mergedAt,mergedBy
```

### Specifying a repository:
```bash
gh pr view 123 --repo acme/backend --json state,mergedAt,mergedBy
```

## Example Output

### Merged PR:
```json
{
  "mergedAt": "2025-01-15T10:30:00Z",
  "mergedBy": {
    "login": "username"
  },
  "state": "MERGED"
}
```

### Open PR:
```json
{
  "mergedAt": null,
  "mergedBy": null,
  "state": "OPEN"
}
```

### Closed (not merged) PR:
```json
{
  "mergedAt": null,
  "mergedBy": null,
  "state": "CLOSED"
}
```

## Error Handling

The skill handles common errors:
- **PR not found**: Returns error message indicating PR doesn't exist
- **Permission denied**: Returns error if user lacks access to repository
- **Invalid repository**: Returns error if repository format is incorrect
- **Network errors**: Returns error if unable to connect to GitHub

## Integration

This skill is used by:
- **swe agent**: Check PR state during implementation workflow
- **jswe agent**: Verify PR status before proceeding

## Benefits

- **Consistency**: Single source of truth for PR state checking
- **Reliability**: Uses official GitHub CLI instead of custom parsing
- **Maintainability**: One place to update if GitHub API changes
- **Structured data**: JSON output for easy parsing and consumption
