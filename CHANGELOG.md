# Changelog

## 0.3.0 — 2026-11-05
- New plugin `agent-ops` 0.1.0: session logging hooks, done-gate Stop hook, skills `agent-ops`, `goal-contract`, `verify-done`, `session-report`.
- Hook script tests: `plugins/agent-ops/tests/run.sh` (29 checks).
- `goal-nudge` UserPromptSubmit hook and done-gate rule 2 (edits without a goal) — added after the first eval showed the agent skipping the goal contract.
- Eval suites: `architecture` (4 cases), `agent-ops` (1 case). `architecture` → 0.2.1.

## 0.2.0 — 2026-11-05
- Restructured into domain plugins. `dev-standards` → `architecture`.
- `system-design` is now an orchestrator; deep areas split into `repo-and-services`, `auth-design`, `data-design`, `api-design`, `adr`.
- Added ROADMAP.md (code-standards, security, devops, collaboration) and UPSTREAM.md (Cloudflare security-audit).

## 0.1.0 — 2026-11-05
- Marketplace scaffold with one plugin and the `system-design` skill.
