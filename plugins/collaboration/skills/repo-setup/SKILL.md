---
name: repo-setup
description: Set a repository up for team collaboration — PR template, CODEOWNERS, branch protection on main, required CI checks, commit-message check, .gitignore for agent and secret files, and a short CONTRIBUTING section. Use when starting a new repo, when the user says "set up the repo for the team", "add a PR template", "protect main", "add CODEOWNERS", "onboard teammates", or when git-workflow finds these missing.
---

# Repo setup

## Steps
1. **Inspect** — what exists: `.github/pull_request_template.md`, `.github/CODEOWNERS`, `.github/workflows/`, `.gitignore`, `CONTRIBUTING.md`, branch protection (`gh api repos/{owner}/{repo}/branches/main/protection`).
2. **PR template** — copy `../pull-requests/templates/PULL_REQUEST.md` to `.github/pull_request_template.md`.
3. **CODEOWNERS** — from ARCHITECTURE.md modules: one line per top-level folder → owner. Template: [templates/CODEOWNERS](templates/CODEOWNERS). Ask the user for GitHub handles; never invent them.
4. **.gitignore** — ensure: `.env*` (except `.env.example`), `.agent-log/sessions/`, `**/evals/**/results/`, build output, OS files.
5. **CI checks** — tests + lint + type-check on every PR; commit-subject check on PR title. Template: [templates/pr-title-check.yml](templates/pr-title-check.yml).
6. **Branch protection** (needs repo admin; **ask before changing**) — require PR, 1 approval, required checks, no force-push, linear history:
   ```bash
   gh api -X PUT repos/{owner}/{repo}/branches/main/protection --input protection.json
   ```
   Show the JSON to the user first. Changing repo settings is outward-facing.
7. **CONTRIBUTING.md** — 10 lines: branch naming, commit format, PR expectations, how to run tests; link the collaboration defaults.

## Hard rules
- Ask before changing GitHub settings, adding owners, or enabling required checks — these affect everyone.
- Don't overwrite an existing PR template or CODEOWNERS; merge into it and show the diff.
