# The contract — who writes and who reads

| File | Written by | Read by |
|---|---|---|
| `docs/spec/SPEC.md` | product-spec, prototype (risk ticks, change log) | everyone |
| `docs/prototypes/<slug>.md` | prototype | system-design, project-plan |
| `docs/architecture/ARCHITECTURE.md` + `adr/` | system-design, adr | every domain skill, code-review |
| `docs/ui/UI.md` | ui-system | shadcn-tailwind, dashboard-patterns, ui-consistency, component-testing |
| `docs/ai/AI.md`, `LEARNINGS.md` | ai-design, ai-learnings | ai-feature, ai-stack, ai-evals, ai-ops |
| `docs/seo/SEO.md` | seo-architecture, keyword-research, search-console | on-page, programmatic-seo, site-audit |
| `docs/security/SECURITY.md` | security-baseline, threat-model | secure-coding, code-review, security-audit |
| `docs/ops/DELIVERY.md` | delivery-pipeline | ci, environments, release-and-rollback |
| `docs/plan/PLAN.md` | project-plan, next-task | next-task, loop.sh, plan-context hook |
| `.agent-log/GOAL.md` | goal-contract | verify-done, done-gate hook |
| `docs/project/BASELINE.md` | project-loop (adopt) | evolve, milestone reviews |
| `docs/project/LOOP.md` | every phase via `loop.sh log` | loop.sh status, the next session |

A skill that needs something it can't find doesn't guess: it names the missing file and the skill that writes it (that's what `loop.sh` does for the whole project).
