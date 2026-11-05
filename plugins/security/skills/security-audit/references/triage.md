# Folding audit results into the project

For each record in the run's `findings.json`:

| Verdict | Goes to | Fields |
|---|---|---|
| `confirmed` | SECURITY.md Baseline table as a **gap** + PLAN.md task | area, control, severity (from report), fix, owner; task `- [ ] T<n> · fix(security): <short> · covers: <R or NFR> · depends: - · size: S` |
| `needs_validation` | SECURITY.md "Open questions" | the exact unresolved fact and what would settle it |
| `rejected` | nothing (kept in the audit dir) | — |

## Severity → deadline (house SLA)
critical 24 h · high 7 days · medium 30 days · low backlog.

## In commits and PRs
- Refer to findings by the audit run path + record ID, not by pasting exploit details.
- Fix PRs: `fix(security): <what>` with a regression test that would have caught it.

## Record the run in SECURITY.md Summary
`Last full audit: YYYY-MM-DD · cloudflare/security-audit (profile) · ~/security-audit-skill/<repo>/run-<N> · n confirmed / n needs_validation`
