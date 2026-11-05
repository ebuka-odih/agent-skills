---
name: environments
description: Define and keep environments consistent — local, preview, staging and production — what differs between them (data, credentials, scale, integrations in test mode), how configuration and secrets reach each one, seeding staging safely, and env-var documentation in .env.example. Use when setting up staging or preview environments, when the user says "staging", "preview deploys", "it works locally but not in prod", "env vars", "config per environment", or when delivery-pipeline routes environment work.
---

# Environments

## The four environments
| | Local | Preview (optional) | Staging | Production |
|---|---|---|---|---|
| Purpose | develop | review a PR | final check before prod | users |
| Data | seed/factories | seed | anonymised copy or realistic seed | real |
| Integrations | fakes / sandbox keys | sandbox keys | sandbox/test-mode keys | live keys |
| Deploys | manual | per PR, auto-destroyed | every merge to main | promoted artifact, approved |
| Who can access | dev | team | team | users; ops via audited access |

## Steps
1. **List every config value** the app reads → `.env.example` with placeholders and one-line comments. Missing from `.env.example` = bug.
2. **Classify** each: build-time vs runtime; secret vs plain; same everywhere vs per-environment. See [references/config.md](references/config.md).
3. **Put values in the platform** (Dokploy/Laravel Cloud/Forge/Fly/Render env settings, GitHub Environments for CI deploy jobs). Never commit real values.
4. **Parity check** — staging runs the same image, same config keys, same migrations path as prod; only values differ. Record differences in DELIVERY.md.
5. **Seed staging safely** — anonymise any production copy (emails, phones, names, payment refs); never email real users from staging (mail trap / allow-list).

## Hard rules
- Production credentials never exist on laptops, in CI logs, or in preview/staging.
- Preview and staging use provider **test mode** (Stripe test keys, sandbox email).
- The app fails at startup when a required config value is missing — not at first use.
