# Changelog

## 1.3.0 — 2026-11-06
- `seo` 0.2.0: new skills `keyword-research` (intent, clusters → one URL, scoring, cannibalization), `search-console` (striking distance, CTR vs position, traffic-drop diagnosis by shape), `page-speed` (Core Web Vitals field p75 + lab, fixes by savings), `site-audit` (live crawl); SEO glossary; SEO.md template gains keyword map, speed table and changes log.
- New scripts: `seo-crawl.sh` (host variants, robots.txt groups, sitemap index, status/redirects/X-Robots-Tag/TTFB/client-rendered shells, then seo-scan on the fetched HTML), `gsc-report.sh` (Search Console export: trend, drop start date, striking distance, low CTR, zero-click pages), `page-speed.sh` (PageSpeed Insights API, `--from-json`, `--lighthouse`, `--strict`).
- `seo-scan.sh`: HTML entities count as one character.
- Tests 64 → 150 (local test server with clean/edge/down/host-variant modes). Mutation: seo-scan 44/44, gsc-report 2/2, page-speed 8/8, seo-crawl 28/30 (2 equivalent: unreachable `per < 1`, TTFB equal to the threshold). Mutation found 17 crawler gaps (host variants, home down, empty sitemap, robots blocking JS, 404 after redirect, 50-sitemap cap) — all now tested; tests found the shell check counting surrounding spaces.
- Tooling: mutation runner neutralises `issue`/`finding` report calls in any position.
- 4 new eval cases (traffic-drop, keyword-map, speed-priorities, audit-handoff) — not yet run (usage limit).
- Run read-only against two live sites; findings handed to the projects' agents.

## 1.2.0 — 2026-11-06
- New plugin `seo` 0.1.0 (technical SEO; content/growth stays a separate plugin): `seo-architecture` (orchestrator → docs/seo/SEO.md), `on-page`, `structured-data`, `programmatic-seo` (indexation thresholds), `international` (hreflang).
- `seo-scan.sh <build-dir> --base <url> [--strict]` audits built HTML: title/description/canonical/h1/lang/OG, JSON-LD validity, hreflang codes + reciprocity + x-default, site-wide duplicates, robots.txt `Disallow: /`, sitemap coverage and noindex pages in sitemaps. One perl pass per page; lengths counted in characters (not bytes) in any locale. 64 tests; mutation 41/41 (100%).
- Tooling: mutation runner gains an `&& issue error|warn` → no-op operator for report-style scanners; `run-all-tests.sh` mutates seo-scan.
- 3 eval cases (seo-plan-from-spec, audit-built-site, local-business-jsonld) — not yet run: usage limit hit; scheduled for after reset.

## 1.1.1 — 2026-11-06
- `frontend` 0.1.1: ui-scan recognises dark themes keyed by `.dark`, `[data-*="dark"]`, `@custom-variant dark` or `prefers-color-scheme`, in any CSS file (was a false "no .dark" gap on a real project); file list normalised and capped.
- `frontend` 0.1.1 / `code-standards` 0.1.4: scanner functions no longer use a shell variable named `path` (it clobbered zsh's command search path when sourced). 8 new regression tests; mutation still 100%.

## 1.1.0 — 2026-11-06
- New plugin `frontend` 0.1.0: `ui-system`, `shadcn-tailwind`, `dashboard-patterns`, `ui-consistency`, `component-testing`, `frontend-performance`; token hook; `ui-scan.sh`; 43 script tests; ui-patterns mutation 9/9; evals token-drift-fix 1.0 (without 0.75), dashboard-page 1.0 (1.0), ui-review 1.0 (1.0). Graders read final files / use regex checks — LLM judges on long traces were truncated.
- Tooling: mutation runner gains awk-rule and exported-regex operators (leftover-scan now 5/5); fuzzing covers 10 hooks.
- `code-standards` 0.1.3: React guide points to the frontend plugin.

## 1.0.1 — 2026-11-06
- devops evals run (blocked by usage limit on 1.0.0): ci-for-fastapi 1.0 (without 0.43), prod-migration-failed 1.0 (0.43), release-plan 1.0 (1.0).

## 1.0.0 — 2026-11-05
- New plugin `devops` 0.1.0: `delivery-pipeline`, `ci` (+ Laravel/FastAPI/Node templates), `environments`, `infrastructure-as-code`, `observability`, `release-and-rollback`; infra guard hook; `devops-scan.sh`; 53 script tests; 3 eval cases (not yet run — usage limit).
- Repo tests itself with its `testing` plugin: `tools/run-all-tests.sh`, `tools/mutate-bash.sh` (bash mutation testing), `tools/fuzz-hooks.sh`, `.github/workflows/ci.yml`, report in `docs/quality/TESTING.md`.
- Mutation testing found and closed real gaps: `security` 0.1.1 (per-pattern tests), `agent-ops` 0.1.2 (per-rule redaction tests, all-ticked gate test).
- `testing` 0.1.1: planner treats guards/gates/redaction as critical; skips eval/test fixtures.

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
