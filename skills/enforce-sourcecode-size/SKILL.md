---
name: enforce-sourcecode-size
description: Enforce file/function/line-length standards on any project (Python, Rust, Go, TypeScript).
inputs: {}
outputs: { claude_md: updated, agents_md: updated, lint_infra: created, pre_commit_hook: created }
dependencies: [ git ]
safety: Modifies repo files; creates scripts, configs, and hooks; commits incrementally.
steps:
  - Detect project language(s) and build system from repo root markers
  - Document size guidelines in CLAUDE.md and AGENTS.md (create or update)
  - Create lint infrastructure (linter config + size-checking scripts + build target)
  - Orchestrate compliance by fixing violations via subagents, committing incrementally
  - Add a pre-commit git hook that runs the lint target (only after all violations resolved)
tooling:
  - commands: /enforce-sourcecode-size
  - Explore agents for codebase discovery; swe agents for violation fixing
---

# enforce-sourcecode-size

Enforce consistent source code size standards across any project. The standards
are language-neutral; the tooling is language-specific.

## Universal Standards

| Metric | Limit |
|--------|-------|
| File length | < 500 lines |
| Function/method body | < 100 lines |
| Line width | < 100 columns |

---

## Step 1: Detect Language & Build System

Scan the repo root to determine language and build system:

| Marker file | Language |
|-------------|----------|
| `pyproject.toml` or `setup.py` or `requirements.txt` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `tsconfig.json` | TypeScript |
| `package.json` (no tsconfig) | JavaScript |

Build system detection (in priority order):
1. `Justfile` or `justfile`
2. `Makefile`
3. `Taskfile.yml`
4. If none found, create a `Justfile`

Also detect if the project uses a runner prefix (e.g., `poetry run`, `cargo`, `npx`)
by checking for `[tool.poetry]` in pyproject.toml, `node_modules/.bin`, etc.

---

## Step 2: Document Guidelines

### CLAUDE.md Section

If `CLAUDE.md` exists at the repo root, find the `## Source Code Size Standard`
heading and replace that section. If the heading does not exist, append the
section at the end. If the file does not exist, create it with a project
philosophy header followed by this section.

Template (substitute `{lint_command}` with the detected build target, e.g.,
`just lint`, `make lint`):

```markdown
## Source Code Size Standard

Run `{lint_command}` before committing. All source files must stay within:
`<500` lines/file, `<100` lines/function, and `<100` columns/line.
```

### AGENTS.md Section

Same create-or-update logic as CLAUDE.md. Template:

```markdown
## Source Code Size Standard

All source files under tracked directories must satisfy:

| Metric | Limit |
|--------|-------|
| File length | < 500 lines |
| Function/method body | < 100 lines |
| Line width | < 100 columns |

Enforcement: run `{lint_command}` before merge. It must pass the configured
linter and size-checking script(s).
```

---

## Step 3: Create Lint Infrastructure

### Python

**Size checker** -- create `scripts/check_python_size.py`:

```python
#!/usr/bin/env python3
"""Check Python files for size thresholds."""

from __future__ import annotations

import ast
from pathlib import Path

MAX_FILE_LINES = 499
MAX_FUNC_LINES = 99
SCAN_DIRS = ("src", "tests", "scripts")
SKIP_DIRS = {
    ".venv",
    "__pycache__",
    ".claude",
    "node_modules",
}


def check_function_sizes(path: Path, source: str) -> list[str]:
    """Return violations for functions exceeding MAX_FUNC_LINES."""
    violations: list[str] = []
    try:
        tree = ast.parse(source, filename=str(path))
    except SyntaxError:
        return violations

    for node in ast.walk(tree):
        if not isinstance(node, ast.FunctionDef | ast.AsyncFunctionDef):
            continue
        end = getattr(node, "end_lineno", None)
        if end is None:
            continue
        length = end - node.lineno + 1
        if length > MAX_FUNC_LINES:
            violations.append(
                f"{path}:{node.lineno}: function '{node.name}' is {length} "
                f"lines (max {MAX_FUNC_LINES})"
            )
    return violations


def check_file(path: Path) -> list[str]:
    """Check a single file for size violations."""
    try:
        source = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return []

    violations: list[str] = []
    line_count = len(source.splitlines())
    if line_count > MAX_FILE_LINES:
        violations.append(
            f"{path}:1: file is {line_count} lines (max {MAX_FILE_LINES})"
        )
    violations.extend(check_function_sizes(path, source))
    return violations


def iter_python_files() -> list[Path]:
    """Return Python files under the configured scan directories."""
    files: list[Path] = []
    for directory in SCAN_DIRS:
        root = Path(directory)
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.py")):
            if any(part in SKIP_DIRS for part in path.parts):
                continue
            files.append(path)
    return files


def main() -> int:
    """Scan repo Python files for size violations."""
    violations: list[str] = []
    for path in iter_python_files():
        violations.extend(check_file(path))

    if violations:
        print(f"Found {len(violations)} size violation(s):\n")
        for violation in violations:
            print(f"  {violation}")
        return 1

    print("All Python files are within size thresholds.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

**Ruff config** -- ensure `pyproject.toml` has:
- `[tool.ruff]` with `line-length = 100`
- `E501` NOT in the `ignore` list under `[tool.ruff.lint]`
- If `[tool.ruff]` does not exist, create it

**Lint target** (Justfile example, prepend `poetry run` if Poetry project):
```just
lint:
    poetry run ruff check .
    poetry run python3 scripts/check_python_size.py
```

### Rust

**Clippy config** -- create or update `clippy.toml`:
```toml
too-many-lines-threshold = 99
```

**Rustfmt config** -- create or update `rustfmt.toml`:
```toml
max_width = 100
```

**File-length checker** -- create `scripts/check_file_sizes.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
MAX_LINES=499
violations=0
while IFS= read -r f; do
  lines=$(wc -l < "$f")
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "$f:1: file is $lines lines (max $MAX_LINES)"
    violations=$((violations + 1))
  fi
done < <(find src tests -name '*.rs' 2>/dev/null | sort)
if [ "$violations" -gt 0 ]; then
  echo -e "\nFound $violations file-size violation(s)."
  exit 1
fi
echo "All Rust files are within size thresholds."
```

**Lint target**:
```just
lint:
    cargo clippy -- -D warnings
    cargo fmt -- --check
    bash scripts/check_file_sizes.sh
```

### Go

**golangci-lint config** -- create or update `.golangci.yml`:
```yaml
linters:
  enable:
    - funlen
linters-settings:
  funlen:
    lines: 99
    statements: -1
  lll:
    line-length: 100
```

Enable `lll` linter for line-length and `funlen` for function length.

**File-length checker** -- create `scripts/check_file_sizes.sh` (same pattern as
Rust but with `*.go` glob and excluding `*_test.go` vendor dirs):
```bash
#!/usr/bin/env bash
set -euo pipefail
MAX_LINES=499
violations=0
while IFS= read -r f; do
  lines=$(wc -l < "$f")
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "$f:1: file is $lines lines (max $MAX_LINES)"
    violations=$((violations + 1))
  fi
done < <(find . -name '*.go' -not -path './vendor/*' 2>/dev/null | sort)
if [ "$violations" -gt 0 ]; then
  echo -e "\nFound $violations file-size violation(s)."
  exit 1
fi
echo "All Go files are within size thresholds."
```

**Lint target**:
```just
lint:
    golangci-lint run
    bash scripts/check_file_sizes.sh
```

### TypeScript / JavaScript

**ESLint config** -- add or update rules in `.eslintrc.*` or `eslint.config.*`:
```json
{
  "rules": {
    "max-len": ["error", { "code": 100 }],
    "max-lines": ["error", { "max": 499, "skipBlankLines": false, "skipComments": false }],
    "max-lines-per-function": ["error", { "max": 99, "skipBlankLines": false, "skipComments": false }]
  }
}
```

For flat config (`eslint.config.mjs`), add the same rules to the rules object.

**Lint target**:
```just
lint:
    npx eslint .
```

---

## Step 4: Orchestrate Compliance

After creating the lint infrastructure, run the lint target and fix violations.

### 4a. Run lint, capture violations

```bash
{lint_command} 2>&1 || true
```

Parse output to categorize: line-width violations vs. function-size vs. file-size.

### 4b. Fix line-width violations first (easiest)

**Python**: Run `ruff format .` to auto-fix most. For remaining E501 (long strings,
comments), use subagents to manually break lines across non-overlapping file groups.

**Rust**: Run `cargo fmt` -- this auto-fixes all line-width issues.

**Go**: Run `golines -w .` if installed, otherwise manual line-breaking.

**TypeScript/JS**: Run `npx eslint --fix .` for auto-fixable issues, then manual.

### 4c. Fix function-size violations (medium effort)

Use subagents (swe type, bypassPermissions) with non-overlapping file groups.
Instructions for each agent:
- Read the oversized function
- Identify logical phases or blocks
- Extract each block into a helper function
- Keep the original function as an orchestrator
- Verify no size violations remain in their files
- Do NOT change logic. Only restructure.

### 4d. Fix file-size violations (hardest)

Use subagents to split modules:
- Identify natural groupings of functions/types within the file
- Create sub-modules and move related code
- Keep backward-compatible re-exports in the original file
- Update internal imports as needed

### 4e. Commit incrementally

After each category of fixes, commit with a descriptive message:
- `"Apply auto-format: fix line-width violations"`
- `"Refactor: split oversized functions to comply with size limits"`
- `"Refactor: split oversized files into sub-modules"`

Re-run lint after each commit. Repeat until clean.

---

## Step 5: Add Pre-Commit Hook

**Only after the lint target passes clean**, create `.git/hooks/pre-commit`:

```bash
#!/usr/bin/env bash
set -euo pipefail
{lint_command}
```

Substitute `{lint_command}` with the detected build target (e.g., `just lint`,
`make lint`).

Make it executable: `chmod +x .git/hooks/pre-commit`

Verify it works by running `git commit --allow-empty -m "test hook"` and
confirming the hook fires.
