---
type: llm
weight: 4
focus: { source: file, path: .github/workflows/backend.yml }
---
PASS only if the workflow:
1. runs on pull requests (and pushes to main), scoped to the backend;
2. installs from the lockfile (uv sync --frozen/--locked) with caching;
3. runs ruff (lint and/or format check), mypy (or pyright) and pytest;
4. runs a dependency audit (pip-audit) and/or a secret scan (gitleaks) — at least one;
5. sets explicit least-privilege `permissions:` (e.g. contents: read) and has a timeout or concurrency setting.
FAIL if any of 1–3 or 5 is missing.
