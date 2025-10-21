---
description: Generate test health report with flaky and slow test analysis
allowed-tools: Bash(make:*), Bash(npm:*), Bash(pytest:*), Read, Grep
---

# Test Engineer: Test Health Report

Analyze test suite health and identify issues.

## Instructions
1. Run test suite (prefer `make test` or similar target)
2. Analyze results for:
   - Flaky tests (inconsistent pass/fail)
   - Slow tests (>5s execution time)
   - Test coverage gaps
   - Skipped/ignored tests
3. Recommend top 5 improvements

See `skills/test_health_report.md` for analysis framework.

## Examples

**Basic usage:**
```
/test-health
```

**Analyzing a specific test suite:**
```
/test-health  # Runs default test target and analyzes results
```

**Common scenarios:**
```
# After noticing flaky tests in CI
/test-health

# Before a release to verify test suite quality
/test-health

# To identify slow tests affecting developer velocity
/test-health
```
