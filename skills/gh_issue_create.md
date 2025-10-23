---
name: gh_issue_create
description: Create GitHub issues with specified type and description
inputs: { type: required, description: required, repo: optional }
outputs: { issue_url: string }
dependencies: [ gh CLI ]
safety: Creates new issues only; does not modify existing content.
steps:
  - Validate issue type (bug/feature/enhancement/etc)
  - Format description according to issue templates
  - Create issue via gh CLI
  - Return issue URL
tooling:
  - gh issue create --title --body
---

# GitHub Issue Creation Skill

This skill creates GitHub issues with proper formatting and templates based on the issue type.

## Usage

The skill accepts the following parameters:
- `type`: The type of issue (bug/feature/enhancement/etc)
- `description`: Description of the issue
- `repo`: Optional repository (defaults to current)

## Issue Types

Supported issue types:
- `bug`: Bug reports and fixes
- `feature`: New feature requests
- `enhancement`: Improvements to existing features
- `docs`: Documentation updates
- `test`: Testing improvements
- `refactor`: Code refactoring tasks

## Templates

Issues will be formatted according to type-specific templates:

### Bug
```markdown
## Description
<description>

## Expected Behavior
[What should happen]

## Current Behavior
[What is happening]

## Steps to Reproduce
1. [First Step]
2. [Second Step]
3. [More Steps...]
```

### Feature/Enhancement
```markdown
## Description
<description>

## Motivation
[Why is this feature needed]

## Proposed Solution
[How should this be implemented]

## Acceptance Criteria
- [ ] [First criterion]
- [ ] [Second criterion]
```

### Other Types
```markdown
## Description
<description>

## Goals
- [First goal]
- [Second goal]

## Notes
[Additional context]
```

## Examples

Creating a bug report:
```bash
/tl ticket TYPE='bug' DESC='Search function returns incorrect results when query contains spaces'
```

Requesting a new feature:
```bash
/tl ticket TYPE='feature' DESC='Add dark mode support to dashboard'
```