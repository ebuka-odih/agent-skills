# Changelog

## 1.10.0 — 2026-11-06
Fixes from the first overnight benchmark, prevention and eval run (results in the README).
- Fast path still loads the domain skill when the file is a job, worker, scheduler, migration or provider client. On the fast path, a retry-loop fix skipped `background-jobs` and missed "every failure sets the retry time" (0.42 vs 1.0). agent-ops 0.1.5, code-standards 0.1.7.
- `background-jobs`: classify provider errors before retrying. 402, quota or out of credits pauses all work for that provider. Both arms of the retry-review prevention case missed this. backend 0.2.1.
- `search-console`: after a sudden drop, name what changed 1–2 days before it (deploy log, CHANGELOG, `git log`, CDN or DNS).
- seo scripts fall back to a temp dir in the working directory when `mktemp -d` fails (sandboxes); `gsc-report.sh` failed inside the eval sandbox. Test included.
- Eval `local-business-jsonld`: the prompt now asks for the markup in the view. The grader reads only the view, and the with-plugins run had (validly) moved the builder into the model. seo 0.2.2.

## 1.9.0 — 2026-11-06
- **Fast path for small changes.** "Small" means a fix or tweak whose expected behaviour the request already states, touching at most ~3 source files, with no schema, public API, auth, money/messages, dependency or deploy change. A small change gets one test, the smallest change in the existing pattern, the module's tests, and a final note with evidence. It needs no GOAL.md, no strategy, and no new docs or helpers. Added because the first benchmarks showed +35% cost with no quality gain on small fixes. The plugins wrote extra helper modules, test files and an unrequested docs update.
  - `goal-nudge` hook sizes the request first: agent-ops 0.1.4.
  - `goal-contract` gains a "Size first" gate.
  - `writing-code` gains a "Fast path" section: code-standards 0.1.6.
  - `test-strategy` says small changes need just one regression test: testing 0.1.3.
  - The loop's phases gain B0: product 0.2.2.
  - Eval `fast-path-small-fix`.
- Bench harness: agents run with `--output-format stream-json`. Each run records the skills it loaded and its tool-call counts, and the report lists them per run, so overhead can be traced to a skill. 69 harness tests.

## 1.8.0 — 2026-11-06
- `devops` 0.2.0: new `uptime` skill and `uptime-scan.sh` (fail-correctly, health checks, monitoring references).
  - Static rules: U1 (upstream 5xx served as 200 via `error_page … = @fallback` or `=200`), U2 (SPA fallback soft 404s), U3 (no health endpoint), U4 (no container healthcheck), U5 (compose without a restart policy), U6 (uvicorn/gunicorn without a graceful timeout).
  - Live probes: U7 (unknown URL must be 404), U8 (health endpoint answers 200 in under 1 s).
  - 25 tests with a local server; mutation 9/9.
  - Live results: project 1's earlier 200-shell outage page is confirmed fixed (503 + Retry-After). Both sites still answer unknown URLs with 200/301 (soft 404).
- `backend` 0.2.0: new skills `concurrency` and `graceful-shutdown`.
  - New scanner rules: C1 check-then-insert (silent when an ON CONFLICT/IntegrityError guard exists), C2 read-modify-write on counters (silent when a row lock exists), G1 polling loop with no stop condition, G2 worker services without `stop_grace_period`. C1/G1 are info in one-off scripts.
  - The C2 check on project 2's credits code was confirmed safe (user row locked).
  - 76 tests.
- Prevention benchmark: `tools/bench/README.md` documents prevention-build and prevention-review cases. 4 private cases are mined from history: a cron that never ran, a retry storm, an outage served as 200, and job-queue hardening.
- Evals: `double-charge`, `deploy-kills-jobs` (backend), `outage-masked` (devops).

## 1.7.0 — 2026-11-06
- New plugin `backend` 0.1.0. Skills: `backend` (orchestrator, with Laravel and FastAPI guides and house defaults), `service-structure`, `migrations` (zero-downtime table), `background-jobs` (job contract, Postgres queue, runners and event loops), `integrations` (outbound policy, webhooks).
- `backend-scan.sh` (newest 30 migrations by default, `--all`, `--strict`) and a PostToolUse hook. Rules:
  - M1–M6 migrations: drop, rename, type change, NOT NULL without default, index on an existing table, SET NOT NULL. They skip `downgrade()`/`down()` and tables created in the same migration, and read SQL and table names across lines.
  - J1–J6 jobs: Laravel jobs without tries/timeout/backoff/failed; Celery autoretry without backoff; `time.sleep` in async code; a thread running its own event loop.
  - O1: `requests` without a timeout, including multi-line calls.
  - S1–S3 schedulers: no overlap guard; arq cron or Celery beat with no deployed worker.
- 62 tests; mutation 20/20 on the rules. The mutation runner now also removes `if (…) print "…"` awk rules, which added 13 mutants to the seo scripts, all killed.
- Real scans (read-only): project 2 has a live thread + `asyncio.run` + shared async engine in its outreach scheduler, the same pattern that hung its directory sync. Project 1 has 8 historical non-concurrent indexes on existing tables. Both handed back.
- Loop: `backend` is a core plugin (`loop.sh plugins`); the build phase names it; `system-design` hands off to it. product 0.2.1, architecture 0.2.4.
- Evals: rename-column-live, retry-storm, thin-handler, provider-hangs. Bench cases from real fixes (project 2 retry storm, project 1 job-queue hardening) are written and verified to discriminate; their runs hit the usage limit and are queued for after the reset.

## 1.6.1 — 2026-11-06
- Bench harness: hidden tests are copied in, run, then removed again, and an agent file at the same path is restored. Before this, the hidden test file leaked into later checks (the agent's `npm test` ran it). The greenfield example's hidden test now runs as `.mjs`, so a CommonJS or ESM app both load. 65 harness tests.
- First real benchmark results, 4 tasks (3 from project 1, 1 greenfield): quality 4/4 with and without plugins; plugins +35% cost and +29% time in total. Details and next steps are in the README. The harness bugs found along the way are fixed.

## 1.6.0 — 2026-11-06
- `frontend` 0.2.0: new `browser-checks` skill and `ui-check` runner (`scripts/ui-check/`), built on Playwright + axe.
  - Runs pages × widths × themes, with media, class, attribute or storage theme strategies.
  - Checks serious/critical axe violations, sideways scroll (naming the culprit leaf elements), broken images, console errors and same-origin 4xx/5xx.
  - Writes a JSON + markdown report and screenshots. Exits 1 on failures and 2 on tool errors.
  - CI template: a PR job against the built app, and a live job after deploy.
  - 16 node tests with a fake Playwright; eval `browser-checks-setup`.
  - Real runs on two production sites found a sideways-scrolling category page (project 1) and 2 serious axe violations plus sideways scroll on a pricing page (project 2).
- Feedback loop: `FEEDBACK.md` plus the repo-local skill `improve-from-feedback`. Project agents report; this repo generalises, tests, ships and hands back.

## 1.5.0 — 2026-11-06
- **Project loop** (`product` 0.2.0): `project-loop` skill (foundation → build loop → release → operate → evolve, plus adopt for existing codebases; phases with exit gates, the contract of who writes and reads each file, evolve rules for features, bugs, signals and scaling). `loop.sh status|next|json|plugins|log` derives the phase from the contract files and names the next skill with the reason; the session-start hook includes it.
- **Profile-based routing**: `## Profile` in SPEC (ui/ai/seo) decides which domains are used. Without one, detection uses code evidence (frontend deps, LLM SDKs, LLM API hosts or keys, sitemap/robots), ignoring tests, fixtures and docs, plus spec words. Mismatches (profile "no", code "yes") are flagged. `loop.sh plugins` writes project settings that disable unneeded plugins.
- **`prototype` skill**: builds on mattpocock/skills `prototype` (logic + UI, delegated when installed) and adds tech, data, AI and flow spikes, success/kill criteria and a timebox before building, and verdicts wired into SPEC risks (K…), the change log, ADRs and the loop. SPEC template gains `## Profile` and `## Risks & unknowns`.
- Hand-off lines in 13 orchestrators plus release-and-rollback (milestone `status: released`). Patch bumps: architecture, frontend, ai-engineering, seo, security, devops, testing, collaboration, code-standards, agent-ops.
- Tests: product 29 → 80; loop.sh mutation 6/6. Evals: `prototype-before-build`, `loop-routes-by-profile` (not yet run).
- Bench harness: the LLM judge runs isolated (empty cwd, no user settings). Before this fix, a Stop hook in the caller's repo used its only turn and every judge check failed silently. `bench.sh rescore` re-grades finished runs without new agent sessions; the agent diff is kept for rescoring. 63 harness tests.
- **First real benchmark** (project 1, nearby-distance formatting): with plugins 1.0 in 202 s / $0.43 / 17 turns; without 1.0 in 728 s / $0.53. Same quality, 3.6× faster, 18% cheaper. The case is easy (the task names the interface); harder cases follow.
- Benchmarks: public greenfield case generator `tools/bench/examples/greenfield-bookings.sh` (brief → deployable API; hidden acceptance tests incl. concurrent double-booking).

## 1.4.0 — 2026-11-06
- Project benchmark harness `tools/bench/bench.sh`: `mine` (candidate fix commits, ★ when tests changed), `new` (case from a shipped commit: base = parent, hidden tests = changed test files), `run` (isolated clone without a remote, with/without arms via `--plugin-dir` and `--setting-sources project,local`, N runs), `score` (hidden tests applied after the agent, cmd, grep present/absent, LLM judge with the shipped diff as reference), and a report of score, checks, turns, cost, time, files and Δ. Runs where the agent errored (usage limit, crash) are marked not graded and left out of averages.
- 53 harness tests with a fake agent and judge (proves the agent never sees hidden tests, the source repo is untouched, and arms differ only by plugins); mutation 6/6.
- `bench-cases/` and `bench-results/` are gitignored: cases describe private projects.

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
