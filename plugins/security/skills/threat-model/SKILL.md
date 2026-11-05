---
name: threat-model
description: Threat-model a feature before building it — draw the data flow and trust boundaries, walk STRIDE (spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege) per boundary, pick mitigations, and record them in docs/security/threats/<feature>.md with tests to prove them. Use when a feature adds new actors, data, integrations, uploads, webhooks, payments, admin powers or AI agents; when the user says "threat model", "what could go wrong security-wise", "is this design safe"; or when security-baseline routes a new feature.
---

# Threat model (STRIDE-lite)

Fifteen minutes before building beats a breach after. Keep it to one page.

## Steps
1. **Scope** — the feature, its requirement IDs (SPEC.md), and the actors (member, admin, anonymous, external service, AI agent).
2. **Data flow** — a small Mermaid diagram: actors → entry points → services → stores → third parties. Mark **trust boundaries** (browser↔server, server↔third party, tenant↔tenant, user text↔AI instructions).
3. **Assets** — what an attacker wants: accounts, money, PII, other tenants' data, admin access, compute/AI spend.
4. **STRIDE per boundary** — for each boundary, ask each question in the template's table. Keep only threats that are plausible for this feature.
5. **Mitigation per threat** — a control from `secure-coding` / `auth-design` / `ai-safety`, or **accept** (with reason and review date).
6. **Prove it** — each mitigation names a test (e.g. "tenant B cannot fetch tenant A's upload → 404") or a config check.
7. **Record** — fill [templates/threat-model.md](templates/threat-model.md) → `docs/security/threats/<feature>.md`; add a row to SECURITY.md; mitigations become acceptance criteria in the feature's PLAN task / GOAL.md.

## Hard rules
- Every threat ends as mitigated (with test), accepted (with reason + date), or transferred (named provider control). None left blank.
- Revisit when the feature's data, actors or integrations change.
