# Roadmap

Each domain is one plugin. Each line under it is one skill. Orchestrator first.

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

## ⏭ code-standards (next)
- `writing-code` — orchestrator: read ARCHITECTURE.md, place code in the right module, follow conventions
- `naming-and-structure` — files, folders, naming per stack
- `error-handling` — errors, logging, retries at code level
- `testing` — what to test, test pyramid, fixtures, coverage gates
- `refactoring` — safe refactor steps, when to stop

## security
- `security-baseline` — orchestrator: the minimum every project ships with
- `secure-coding` — input validation, output encoding, secrets, dependency hygiene
- `threat-model` — STRIDE-lite per feature
- `security-audit` — delegate to Cloudflare's `security-audit` (see UPSTREAM.md) for full audits; add house rules on top

## devops
- `delivery-pipeline` — orchestrator: CI → preview → staging → production
- `ci` — required checks, caching, affected-only builds
- `environments-and-secrets` — env parity, config, secret stores
- `infrastructure-as-code` — Terraform/OpenTofu layout and rules
- `observability` — logs, metrics, traces, alerts, SLOs
- `release-and-rollback` — deploy strategies, feature flags, rollback drill

## collaboration
- `git-workflow` — orchestrator: branch naming, trunk-based flow, rebasing rules
- `commits` — Conventional Commits, atomic commits, message format
- `pull-requests` — PR size, description template, checklist, linking issues
- `code-review` — reviewer checklist, comment tone, approval rules
- `issues-and-planning` — issue templates, definition of done
