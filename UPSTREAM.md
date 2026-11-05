# Upstream skills

Third-party skills we install alongside ours or learn from. Vet before adding: read every file, not just SKILL.md — skill text runs with full agent trust and bundled scripts run with your permissions.

| Skill | Source | License | Used for | Status |
|---|---|---|---|---|
| `security-audit` | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | MIT | Full multi-phase security audits with verified, machine-readable findings. Our `security` plugin will delegate full audits to it. | Reviewed SKILL.md 2026-11-05 · not yet installed |

## cloudflare/security-audit-skill — notes
- One skill, `skills/security-audit/`, split into topic files (`WEB-PROTOCOL-AND-AUTH.md`, `SUPPLY-CHAIN-AND-RELEASE.md`, `CLOUD-AND-DEPLOYMENT.md`, …) plus a JSON report schema and two Node validators.
- Two modes: **guidance** (default — use only the relevant parts) and **full audit** (six phases, writes report artifacts outside the repo).
- Runs target code only inside an OS sandbox; otherwise reviews source only.
- Needs a coding agent that can run parallel sub-agents, and Node.js for the validators.
- Install: `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit`

Patterns borrowed for this repo: guidance-vs-full mode split, topic files loaded on demand, machine-checkable output.
