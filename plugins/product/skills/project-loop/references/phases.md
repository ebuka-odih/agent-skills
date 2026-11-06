# Phases, skills and exit gates

🧑 = ask the user (decision only they can make). Everything else the agent runs on its own.

| # | Phase | Skill(s) | Reads | Writes | Exit gate |
|---|---|---|---|---|---|
| F1 | Define 🧑 | `product:product-spec` | the user's idea | `docs/spec/SPEC.md` (R…, non-goals, **Risks K…**) | every must-requirement has an `accept:` check; risks listed |
| F2 | Prototype 🧑 verdict | `product:prototype` | SPEC risks | `docs/prototypes/<slug>.md`, SPEC change log, ADR | no open `- [ ] K…` risk |
| F3 | Architecture | `architecture:system-design` (+ `adr`) | SPEC, prototype verdicts | `docs/architecture/ARCHITECTURE.md` | every requirement maps to a component; costly choices have ADRs |
| F4 | Domain design (as needed) | `frontend:ui-system`, `ai-engineering:ai-design`, `seo:seo-architecture` | SPEC, ARCHITECTURE | `docs/ui/UI.md`, `docs/ai/AI.md`, `docs/seo/SEO.md` | `loop.sh` no longer asks for them |
| F5 | Guardrails | `security:security-baseline`, `devops:delivery-pipeline`, `testing:test-strategy`, `collaboration:repo-setup` | ARCHITECTURE | `docs/security/SECURITY.md`, `docs/ops/DELIVERY.md`, CI workflow, branch rules | CI runs on an empty PR and passes |
| F6 | Plan | `product:project-plan` | everything above | `docs/plan/PLAN.md` (M0 foundations, M1…; tasks cover R…) | every must-requirement covered by a task (`trace.sh`) |
| B | Build loop (per task) | `product:next-task` → `agent-ops:goal-contract` → domain skills (`backend` for server code, migrations and jobs; `code-standards`, `frontend`, `ai-engineering`, `seo`, `security:secure-coding`) → `testing` → `collaboration:git-workflow/commits/pull-requests/code-review` → `agent-ops:verify-done` | PLAN, all design docs | code, tests, PR, PLAN tick + progress log | task's GOAL criteria PASS; CI green; PR reviewed |
| R | Release 🧑 go/no-go | `devops:release-and-rollback`, `devops:environments`, `seo:site-audit` + `seo:page-speed` (public sites), `security:security-audit` (before first public launch) | DELIVERY.md, milestone | release notes, milestone `status: released` | deployed, smoke checks pass, rollback tested |
| O | Operate | `devops:observability`, `seo:search-console`, `ai-engineering:ai-learnings`, `ai-ops` | production signals | alerts, LEARNINGS.md, SEO.md changes log | SLOs/alerts in place; first week's signals reviewed |
| E | Evolve | [evolve.md](evolve.md) | requests, bugs, metrics | SPEC change log → PLAN tasks | the change is a planned task with requirement IDs |

## Gate checks you can run
| Gate | Command |
|---|---|
| Requirements covered | `bash plugins/product/scripts/trace.sh docs/spec/SPEC.md docs/plan/PLAN.md` |
| Next step | `bash plugins/product/scripts/loop.sh next` |
| Task done | `agent-ops:verify-done` (GOAL.md criteria with evidence) |
| Code quality | `code-standards` leftover-scan; `testing` test-plan.sh |
| Security | `security` security-scan.sh; secret guard hook |
| UI | `frontend` ui-scan.sh |
| SEO | `seo` seo-scan.sh (build) / seo-crawl.sh (live) |
| Delivery | `devops` devops-scan.sh; CI status |
