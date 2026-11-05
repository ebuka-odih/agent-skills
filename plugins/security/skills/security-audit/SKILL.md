---
name: security-audit
description: Run a full security audit or pen test of a codebase by delegating to Cloudflare's open-source security-audit skill (cloudflare/security-audit-skill) — check it's installed, ask before installing, choose guidance vs full-audit mode, keep output outside the repo, then turn confirmed findings into SECURITY.md gaps and plan tasks. Use when the user says "security audit", "pen test", "find vulnerabilities", "comprehensive security review", "audit this codebase", or before a launch or a funding/customer security questionnaire.
---

# Security audit (delegates to Cloudflare's skill)

We don't reinvent a vulnerability-hunting harness. Cloudflare's `security-audit` skill runs a six-phase audit (reconnaissance → hunting → independent validation → schema-checked findings → verification → report). This skill sets it up, runs it safely, and folds the results back into this project's records. Details: [references/cloudflare.md](references/cloudflare.md).

## Steps
1. **Is it installed?** Look for a `security-audit` skill in the session's skill list, or on disk: `ls ~/.claude/skills/security-audit/SKILL.md .claude/skills/security-audit/SKILL.md 2>/dev/null`.
2. **Not installed → ask the user first** (it downloads third-party code). Show the command and what it does:
   ```bash
   npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global
   ```
   Requirements: Node.js; a model with parallel sub-agents. After install, a new session picks it up.
   If the user declines → fall back to `secure-coding` + `threat-model` on the riskiest areas and say coverage is partial.
3. **Pick the mode** with the user:
   | Ask | Mode |
   |---|---|
   | A question, one file, one finding | **guidance** — no report files |
   | "Audit / pen-test the codebase", "comprehensive", report wanted | **full audit** — six phases, report files |
   | Large / high-stakes | full audit, profile `deep`; small or re-run → `quick` |
4. **Output stays outside the repo** — default `~/security-audit-skill/<repo>/run-<N>`. Never commit audit artifacts; they describe exploitable weaknesses.
5. **Run it**: ask in the target repo, e.g. "security audit this codebase, output to ~/audits/<repo>". Let it follow its own sandbox rules — if it reports a missing sandbox, findings stay `needs_validation`; don't work around it.
6. **Fold results back** — [references/triage.md](references/triage.md): each `confirmed` finding → a SECURITY.md gap (severity, fix, owner) and, if a plan exists, a PLAN.md task `fix(security): …` covering the affected requirement. `needs_validation` items → listed with the exact blocker. Record the run (date, profile, report path) in SECURITY.md.

## Hard rules
- Ask before installing or updating the third-party skill. Read its SKILL.md before first use (it runs with full agent trust).
- Never point it at production systems, shared infrastructure or code you aren't authorised to test.
- Report paths, not report contents, in commits and PRs.
