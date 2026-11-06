---
name: security-baseline
description: Entry point for security in a project — set and track the minimum every project ships with (auth, authorization, input handling, secrets, dependencies, headers, logging, backups), record it in docs/security/SECURITY.md, and route to secure-coding (reviewing code), threat-model (new feature), secrets-and-deps (keys and packages) or security-audit (full audit via Cloudflare's skill). Use when starting a project, before launch, when the user asks "is this secure", "security checklist", "security review", "harden this", "pen test", "audit", or when a change touches auth, payments, uploads, webhooks or PII.
---

# Security baseline (orchestrator)

Security is a list of specific controls, each either in place, not needed (with a reason), or a tracked risk. This skill keeps that list true.

```
security/skills/
├── security-baseline/  ← you are here: the baseline, SECURITY.md, routing
├── secure-coding/      OWASP-mapped rules per stack; reviewing a diff
├── threat-model/       STRIDE-lite per feature before it's built
├── secrets-and-deps/   keys, .env, rotation, dependency audits, lockfiles
└── security-audit/     full audit / pen test → Cloudflare security-audit skill
```

**Output in the project:** `docs/security/SECURITY.md` (from [templates/SECURITY.md](templates/SECURITY.md)) · `docs/security/threats/<feature>.md`

## Pick the mode
| Request | Mode | Do |
|---|---|---|
| New project / "security checklist" / before launch | **Baseline** | Steps 1–4 |
| "Review this change" / PR touches auth, input, files, webhooks, PII | **Review** | `secure-coding` on the diff |
| New feature with new data, actors or integrations | **Threat model** | `threat-model` |
| Keys, `.env`, leaked secret, dependency alert | **Hygiene** | `secrets-and-deps` |
| "Audit", "pen test", "comprehensive security review" | **Audit** | `security-audit` |

## Baseline steps
1. **Read what exists:** ARCHITECTURE.md §7–8 (auth), §9 (data/PII), §17 (security); AI.md safety section; existing `docs/security/SECURITY.md`.
2. **Run the scan:** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/security-scan.sh"` — tracked secrets, tracked `.env` files, `.gitignore` gaps, and the dependency-audit commands for this stack. Run the audit commands it prints.
3. **Walk the baseline:** [references/baseline.md](references/baseline.md). For each control: **in place** (cite file/config) · **N/A** (why) · **gap** (owner + fix + severity).
4. **Write SECURITY.md** and tell the user: gaps ranked by severity, each with the concrete fix.

House defaults: [references/defaults.md](references/defaults.md).

## Hard rules
- Evidence for "in place" is a file path, config value or command result — never "the framework handles it".
- Defensive work only: never test against production, third-party systems or other people's data. See `security-audit` for sandbox rules.
- A found secret is a **rotation**, not just a deletion — git history keeps it.
- Severity uses impact × likelihood (critical / high / medium / low); don't inflate.

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log foundation/design "SECURITY.md"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
