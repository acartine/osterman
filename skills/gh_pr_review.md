---
name: gh_pr_review
description: Fetch PR diff, perform structured review, and post findings as PR comment.
inputs: { repo: required, pr_number: required, post_comment: optional (default true) }
outputs: { review_summary: markdown, findings: list, review_status: string }
dependencies: [ gh CLI ]
safety: Read-only by default; review comments require approval or agent autonomy. Note: Uses comment-only reviews, no formal GitHub approvals.
steps:
  - Fetch diff + metadata (files, labels, checks, size, authors).
  - Run quality checklist: correctness, security, performance, tests, docs.
  - Summarize architectural impacts and risk level.
  - Draft review with Critical/Important/Suggestions.
  - Post review comment to PR using gh pr review.
  - Return review status: ready_to_merge, changes_requested, or comment.
tooling:
  - commands: bin/gh-pr-review
  - gh pr view --json; gh pr diff; gh pr review --comment/--request-changes (never uses --approve)
---

# PR Review Skill

## Overview
Performs comprehensive PR review and posts structured feedback directly to the PR.

## Usage
```bash
# Review PR and post comment
gh pr view <num> --repo <org/name> --json number,title,author,mergeable,state,url,headRefOid
gh pr diff <num> --repo <org/name>
gh pr checks <num> --repo <org/name>
```

## Review Process

### 1. Fetch PR Information
- Get PR metadata including HEAD SHA for change detection
- Fetch diff to analyze changes
- Check CI status

### 2. Analyze Quality
Review these dimensions:
- **Correctness**: Logic errors, edge cases, business logic
- **Security**: Injection risks, auth/authz, secrets, dependencies
- **Performance**: N+1 queries, inefficient algorithms, resource leaks
- **Tests**: Coverage, test quality, missing test cases
- **Documentation**: Comments, README updates, API docs
- **Code Quality**: Readability, maintainability, patterns

### 3. Categorize Findings
- **Critical**: Must fix before merge (security, data loss, breaking)
- **Important**: Should fix before merge (bugs, performance, missing tests)
- **Suggestions**: Nice to have (style, refactoring, improvements)

### 4. Assess Risk Level
- **Low Risk**: <100 lines, well-tested, green CI, docs updated
- **Medium Risk**: 100-500 lines, some test gaps, mostly green CI
- **High Risk**: >500 lines, missing tests, red CI, breaking changes

### 5. Post Review to PR
Based on risk and findings, use appropriate review action (NOTE: Never uses formal GitHub approvals):

**Ready to Merge** (Low/Medium risk, no Critical/Important findings):
```bash
gh pr review <num> --repo <org/name> --comment --body "✅ **Review Decision: Ready to merge**\n\n<review_summary>"
```

**Request Changes** (Critical findings or High risk):
```bash
gh pr review <num> --repo <org/name> --request-changes --body "<review_summary>"
```

**Comment** (Important findings, needs discussion):
```bash
gh pr review <num> --repo <org/name> --comment --body "<review_summary>"
```

### 6. Review Body Format
```markdown
## Review Summary
<1-2 sentence overview of what this PR does>

## Risk Assessment: <Low/Medium/High>
<Reasoning for risk level>

## Findings

### Critical
- [ ] <finding with file:line reference>

### Important
- [ ] <finding with file:line reference>

### Suggestions
- <suggestion>

## Merge Readiness
<Ready / Not Ready / Ready with changes>

## Next Steps
<What author should do>
```

## Return Values
- `review_summary`: Full markdown review text
- `findings`: List of categorized findings
- `review_status`: "ready_to_merge" | "changes_requested" | "comment"
- `head_ref_oid`: Current HEAD SHA (for change detection)
