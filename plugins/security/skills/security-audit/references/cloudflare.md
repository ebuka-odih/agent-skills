# Cloudflare security-audit skill — what to know

Source: https://github.com/cloudflare/security-audit-skill (MIT). Reviewed 2026-11-05. Listed in this repo's UPSTREAM.md.

## Install
```bash
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit           # project
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global  # user-level
```
`npx skills --help` for agent selection and non-interactive options.

## Modes
- **Guidance** (default): security questions, focused reviews, triage — uses only the relevant parts, writes no files.
- **Full audit**: explicit audit/pen-test, "comprehensive/end-to-end", or report requested — six phases, report files.
- If ambiguous, it asks one question before creating files.

## Phases (full audit)
1. Reconnaissance → `architecture.md`, `coverage-ledger.json`
2. Coverage-led hunting with isolated hunters + coverage critics
3. Candidate validation by fresh verifiers that try to disprove each finding
4. Structured output → `findings.json` validated against `report-schema.json`
5. Independent record verification
6. Reporting → `REPORT.md`, `FINDINGS-DETAIL.md`, `NEEDS-VALIDATION.md`

Verdicts: `confirmed` (complete source trace + bounded observed result), `needs_validation` (exact unresolved fact, no severity), `rejected`.

## Profiles
`quick` (one hunter wave, partial coverage) · `standard` (default) · `deep` (per-subsystem units, critic waves to a clean pass). Scoped runs (paths, subsystem, diff between refs) report partial coverage.

## Output
Default `~/security-audit-skill/<repo-name>/run-<N>`; inside the repo only if you pick a directory version control ignores. Runs are additive: later runs read prior ledgers/findings to target gaps.

## Safety model
Source inspection is read-only. Target code (builds, tests, fuzzers) runs only inside an OS-enforced sandbox: no external network, allow-listed environment, read-only target, resource limits. Without one, it doesn't execute target code and marks leads `needs_validation`. No probing of deployed endpoints, shared infrastructure or real users' data.

## Topic files worth reading for our stacks
`WEB-PROTOCOL-AND-AUTH.md` (Laravel/FastAPI auth) · `AI-AND-LLM.md` (AI features) · `DATA-ISOLATION-AND-LIFECYCLE.md` (multi-tenant) · `SUPPLY-CHAIN-AND-RELEASE.md` (CI, deps) · `CLOUD-AND-DEPLOYMENT.md` (infra) · `PROTOCOLS-RPC-AND-MESSAGING.md` (webhooks, queues).
