# Changelog

## 0.9.0 — 2026-11-05
- New plugin `testing` 0.1.0: `test-strategy`, `mutation-testing`, `property-based`, `contract-testing`, `e2e-testing`, `non-functional`; `test-plan.sh`, `test-tools.sh`; 22 script tests; 4 eval cases.
- `code-standards` 0.1.2: `testing` and `writing-code` route to `test-strategy`.

## 0.8.0 — 2026-11-05
- New plugin `security` 0.1.0: `security-baseline`, `secure-coding`, `threat-model`, `secrets-and-deps`, `security-audit` (Cloudflare delegate); secret guard hook; `security-scan.sh`; 24 script tests; 4 eval cases.
- `code-standards` 0.1.1: TODO/FIXME/XXX matched as whole words only (XXXX placeholders were false positives).

## 0.7.0 — 2026-11-05
- New plugin `code-standards` 0.1.0: `writing-code`, `structure-and-naming`, `error-handling`, `testing`, `refactoring`; `project-commands.sh`, `leftover-scan.sh`, PostToolUse leftover hook; 35 script tests; 3 eval cases.

## 0.6.0 — 2026-11-05
- New plugin `collaboration` 0.1.0: `git-workflow`, `commits`, `pull-requests`, `code-review`, `repo-setup`; PreToolUse git guard; `pr-prep.sh`; 31 script tests; 4 eval cases.

## 0.5.0 — 2026-11-05
- New plugin `ai-engineering` 0.1.0: 7 skills (ai-design, ai-feature, ai-stack, ai-evals, ai-safety, ai-ops, ai-learnings), SessionStart drift hook, 10 script tests, 4 eval cases. House defaults seeded from two FastAPI + Pydantic AI projects.
- `product` 0.1.1: lifecycle routes AI requirements to ai-design.

## 0.4.0 — 2026-11-05
- New plugin `product` 0.1.0: `product`, `product-spec`, `project-plan`, `next-task`; SessionStart hook with project status; `trace.sh` traceability; 29 script tests; 4 eval cases.
- `agent-ops` 0.1.1: GOAL.md links to a plan task (`task:`, `covers:`); verify-done updates PLAN.md.
- `architecture` 0.2.2: system-design reads SPEC.md before asking drivers.

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
