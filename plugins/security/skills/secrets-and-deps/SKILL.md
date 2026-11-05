---
name: secrets-and-deps
description: Keep secrets and dependencies safe — where secrets live (secret store, gitignored .env, .env.example placeholders), what to do when a secret leaks (rotate first, then clean history), scanning the repo for committed secrets, and auditing dependencies (composer audit, pip-audit / uv, npm audit), lockfiles and update policy. Use when adding an API key or credential, when the user says "where do I put this key", "I committed a secret", "leaked key", "dependency vulnerability", "npm audit", "Dependabot alert", or when the secret guard hook blocks a write.
---

# Secrets and dependencies

## Adding a secret
1. Add the **name** with a placeholder to `.env.example` (`STRIPE_SECRET=`), never the value.
2. Read it through typed config: Laravel `config/services.php` → `env('STRIPE_SECRET')`; FastAPI `Settings(BaseSettings)`; frontend → **never** (server only).
3. Put the real value in the local `.env` (gitignored) and the platform secret store for each environment.
4. Least privilege: restricted/test keys in dev; separate keys per environment.

The **secret guard hook** blocks writing high-confidence secrets (private keys, live API keys, cloud keys, tokens) into tracked files. Put them in `.env` (gitignored) instead.

## A secret leaked (committed, pasted, logged)
Follow [references/leak-response.md](references/leak-response.md). Order matters: **rotate → verify old key dead → then clean history**. Deleting the line doesn't un-leak it.

## Scan
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/security-scan.sh"
```
Finds tracked secrets, tracked `.env*` files, `.gitignore` gaps, and prints this stack's dependency-audit commands. If `gitleaks` or `trufflehog` is installed, also run it on full history.

## Dependencies
[references/dependencies.md](references/dependencies.md) — audit commands, lockfile rules, update policy, picking packages.

## Hard rules
- Secrets never appear in code, tests, fixtures, logs, commit messages, PR bodies, issues or chat.
- Lockfiles are committed; CI installs from them (`composer install`, `uv sync --frozen`, `npm ci`).
- High/critical dependency advisories block merge unless an exception is recorded in SECURITY.md with a date.
