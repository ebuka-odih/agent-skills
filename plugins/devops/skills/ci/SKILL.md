---
name: ci
description: Set up or fix continuous integration — the checks every pull request runs (format, lint, types, tests, dependency audit, secret scan, PR title, scoped mutation/contract/AI evals), caching, frozen installs from lockfiles, least-privilege permissions, pinned actions, concurrency, and fast feedback. Includes GitHub Actions templates for Laravel, FastAPI (uv) and Node/React. Use when the user says "add CI", "GitHub Actions", "the pipeline is slow", "CI is failing", "required checks", or when delivery-pipeline routes CI work.
---

# CI

## Steps
1. **See what runs today** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/devops-scan.sh"` lists workflows and which checks are missing.
2. **Get the project's real commands** — code-standards `project-commands.sh` (format/lint/types/test per folder). CI runs exactly those.
3. **Start from a template** (copy, then adapt paths/versions):
   | Stack | Template |
   |---|---|
   | Laravel / PHP | [templates/laravel.yml](templates/laravel.yml) |
   | FastAPI / Python (uv) | [templates/fastapi.yml](templates/fastapi.yml) |
   | Node / React / TS | [templates/node.yml](templates/node.yml) |
   | Monorepo | one workflow per app with `paths:` filters, or one workflow with jobs gated by `dorny/paths-filter` |
4. **Add the cross-domain gates** — dependency audit + secret scan (security), PR-title check (collaboration `repo-setup`), changed-files mutation and contract diff (testing), AI evals when prompts change (ai-engineering). See [references/rules.md](references/rules.md).
5. **Make checks required** on `main` (repo-setup branch protection) — ask the user before changing repo settings.
6. **Measure** — PR CI target < 10 minutes. Slow → cache, parallelise, move heavy jobs (load, full E2E, full mutation) to nightly.

## Hard rules
- Installs are frozen: `composer install --no-interaction --prefer-dist`, `uv sync --frozen`, `npm ci` / `pnpm install --frozen-lockfile`.
- `permissions:` set explicitly (default `contents: read`); secrets only in the jobs that need them; never echo secrets.
- Third-party actions pinned to a full commit SHA (with a version comment); first-party `actions/*` at least to a major tag.
- A red `main` is fixed or reverted before anything else merges.
