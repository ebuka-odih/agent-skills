# Upstream skills

Third-party skills we install alongside ours or learn from. Vet before adding: read every file, not just SKILL.md — skill text runs with full agent trust and bundled scripts run with your permissions.

| Skill | Source | License | Used for | Status |
|---|---|---|---|---|
| `security-audit` | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | MIT | Full multi-phase security audits with verified, machine-readable findings. The `security` plugin's `security-audit` skill delegates full audits to it. | Reviewed SKILL.md + README 2026-11-05 · installed per machine on request |
| `prototype` | [mattpocock/skills](https://github.com/mattpocock/skills) (`mattpocock-skills` plugin) | MIT | Logic demos (one-file HTML over a pure module) and UI variants (`?variant=` + floating switcher). `product:prototype` delegates those two shapes to it when installed and summarises its rules otherwise. | Reviewed SKILL.md, LOGIC.md, UI.md 2026-11-06 |

## cloudflare/security-audit-skill — notes
- One skill, `skills/security-audit/`, split into topic files (`WEB-PROTOCOL-AND-AUTH.md`, `SUPPLY-CHAIN-AND-RELEASE.md`, `CLOUD-AND-DEPLOYMENT.md`, …) plus a JSON report schema and two Node validators.
- Two modes: **guidance** (default — use only the relevant parts) and **full audit** (six phases, writes report artifacts outside the repo).
- Runs target code only inside an OS sandbox; otherwise reviews source only.
- Needs a coding agent that can run parallel sub-agents, and Node.js for the validators.
- Install: `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit`

Patterns borrowed for this repo: guidance-vs-full mode split, topic files loaded on demand, machine-checkable output.

## mattpocock/skills `prototype` — notes
- Two branches: **logic** (single shareable HTML, pure reducer/state machine module, free-play buttons + guided scenario tabs, domain language) and **UI** (3–5 structurally different variants on the existing route, `?variant=`, keyboard-navigable floating switcher hidden in production).
- Throwaway from day one; trivially runnable; no persistence; no tests; surface state; capture the prototype on a throwaway branch and the verdict in the issue.
- What `product:prototype` adds: tech/data/AI/flow spikes, success + kill criteria and a timebox written before building, verdicts wired into SPEC risks, the SPEC change log, ADRs and the project loop.
