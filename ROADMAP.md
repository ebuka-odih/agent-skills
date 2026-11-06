# Roadmap

Each domain is one plugin. Each line under it is one skill. Orchestrator first.

## ✅ backend (0.1)
- `backend` — orchestrator: stack guides (Laravel, FastAPI), house defaults
- `service-structure` — layers, transactions, errors
- `migrations` — zero-downtime patterns
- `background-jobs` — job contract, Postgres queues, runners, schedulers, event loops
- `integrations` — outbound policy, circuit breaker, webhooks
- Next: uptime & outage behaviour (503 + Retry-After, health/readiness, alerts)

## ✅ seo (0.2)
- `seo-architecture` — orchestrator: rendering, URLs, indexation, SEO.md
- `on-page` — head tags per page + stack snippets
- `structured-data` — schema.org types per page, JSON-LD from data
- `programmatic-seo` — templates, indexation thresholds
- `international` — locale scheme, hreflang
- `keyword-research` — intent, clusters, one URL each, keyword map
- `search-console` — rankings, striking distance, CTR, drop diagnosis
- `page-speed` — Core Web Vitals field + lab, fixes by savings
- `site-audit` — live crawl: hosts, robots, sitemaps, redirects, noindex, shells
- Next: `growth` plugin (content briefs, posts, distribution) — separate from technical SEO

## ✅ frontend (0.1)
- `ui-system` — orchestrator: tokens, layers, UI.md
- `shadcn-tailwind` — theming, status tokens, cva, banned classes
- `dashboard-patterns` — layout, tables, charts, forms, URL state, data states
- `ui-consistency` — drift review checklist
- `component-testing` — stories, interaction, visual, axe, MSW
- `frontend-performance` — Web Vitals, bundle budgets, common fixes
- Next: shared `packages/ui` template with the starter app components + stories

## ✅ devops (0.1)
- `delivery-pipeline` — orchestrator: stages, gates, DELIVERY.md
- `ci` — rules + Laravel / FastAPI / Node templates
- `environments` — four environments, config vs secrets
- `infrastructure-as-code` — platform choice, Dockerfiles, Terraform rules
- `observability` — logs, metrics, traces, SLOs, alerts
- `release-and-rollback` — strategies, migrations, flags, incident runbook

## Everything planned is built — next ideas
- Promote cross-project lessons (ai-engineering learning loop) into house defaults
- Make architecture / code-standards evals test house-specific rules so they discriminate
- CI templates: nightly k6, PR mutation on changed files per stack

## ✅ testing (0.1)
- `test-strategy` — orchestrator: conditions → techniques, budget, test-plan.sh
- `mutation-testing` — Pest --mutate, Infection, mutmut, Stryker on changed files
- `property-based` — Hypothesis, fast-check, PHP options
- `contract-testing` — oasdiff, Schemathesis, Pact
- `e2e-testing` — Playwright critical journeys, flake policy
- `non-functional` — k6 load, axe accessibility, visual regression
- Next: CI workflow templates per stack (PR mutation on changed files, nightly k6)

## ✅ security (0.1)
- `security-baseline` — orchestrator: checklist → SECURITY.md, routing
- `secure-coding` — OWASP-mapped rules for Laravel / FastAPI / React
- `threat-model` — STRIDE-lite per feature with proofs
- `secrets-and-deps` — secret handling, leak response, dependency audits
- `security-audit` — full audits via Cloudflare security-audit skill
- Next: security headers / CSP templates per stack; CI templates for dependency audit + gitleaks

## ✅ code-standards (0.1)
- `writing-code` — orchestrator: read rules → copy pattern → test → code → format/lint/types/tests → leftover scan
- `structure-and-naming` — placement, naming per stack, size limits
- `error-handling` — edge/inside/outside layers, status mapping, retry rules
- `testing` — levels, cases from acceptance criteria, fakes, stack examples
- `refactoring` — characterization tests, safe moves, strangler
- Next: per-stack linter config templates (pint.json, ruff.toml, eslint) and arch-test templates

## ✅ collaboration (0.1)
- `git-workflow` — orchestrator: lifecycle + hard rules
- `commits` — Conventional Commits, atomic, never-commit list
- `pull-requests` — sizing, body from PLAN + GOAL evidence, checks, merge
- `code-review` — checklist, labelled comments, verdict, reviewing agent PRs
- `repo-setup` — PR template, CODEOWNERS, PR-title check, branch protection
- Next: release notes / changelog from Conventional Commits; GitHub Issues ↔ PLAN.md sync

## ✅ ai-engineering (0.1)
- `ai-design` — orchestrator: discovery, AI.md, check mode
- `ai-feature` — per-feature card: pattern, contract, tier, fallback, evals, budget
- `ai-stack` — Laravel AI SDK · FastAPI + Pydantic AI · split · other stacks
- `ai-evals` · `ai-safety` · `ai-ops` — quality gates, guardrails, cost and rollout
- `ai-learnings` — project lessons → house defaults
- Next: eval-runner scaffolds per stack (pytest + Pest), usage-table migrations for both stacks

## ✅ product (0.1)
- `product` — orchestrator: which stage (define → design → plan → build)
- `product-spec` — interview → SPEC.md, requirement IDs, change control
- `project-plan` — milestones + tasks traced to requirements, re-sync on spec change
- `next-task` — one task per goal, update plan + progress log, resume across sessions
- Next: GitHub Issues sync for PLAN.md tasks (team view)

## ✅ agent-ops (0.1)
- `agent-ops` — orchestrator: log + goal + verify loop
- `goal-contract` — GOAL.md with checkable criteria before work
- `verify-done` — evidence per criterion before claiming done
- `session-report` — claims vs actions from the session log
- Next: done-gate cross-checks that each evidence command ran (ok) in the session log after the last edit

## ✅ architecture (0.2)
- `system-design` — orchestrator, drivers, 18-area checklist, ARCHITECTURE.md, check mode
- `repo-and-services` — monorepo/polyrepo, monolith/services, boundaries, communication
- `auth-design` — authentication, authorization, multi-tenancy
- `data-design` — stores, ownership, migrations, backups, PII
- `api-design` — style, conventions, versioning, webhooks
- `adr` — write and supersede decision records

