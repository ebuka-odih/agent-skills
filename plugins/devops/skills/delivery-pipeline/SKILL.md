---
name: delivery-pipeline
description: Entry point for getting code from a merged PR to production safely — the pipeline shape (CI → preview → staging → production), the gates at each stage, environments, infrastructure, observability and release/rollback — recorded in docs/ops/DELIVERY.md. Use when setting up deployment for a project, when the user says "set up CI/CD", "deploy this", "how do we ship", "devops", "pipeline", "staging", "production", "release process", or when a deploy fails. Routes to ci, environments, infrastructure-as-code, observability and release-and-rollback.
---

# Delivery pipeline (orchestrator)

```
devops/skills/
├── delivery-pipeline/     ← you are here: stages, gates, DELIVERY.md
├── ci/                    the checks every PR runs; templates for Laravel, FastAPI, Node
├── environments/          local / preview / staging / production; config and secrets per env
├── infrastructure-as-code/ hosting, Docker, Terraform/OpenTofu, PaaS config — reviewed like code
├── observability/         logs, metrics, traces, SLOs and alerts
└── release-and-rollback/  deploy strategy, migrations, feature flags, rollback drill
```

**Output:** `docs/ops/DELIVERY.md` — stages, gates, environments, deploy target, how to roll back, who's on call.

## Steps
1. **Read what exists** — ARCHITECTURE.md §11–15 (hosting, environments, delivery, observability, reliability); existing CI and deploy files. Run:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/devops-scan.sh"
   ```
   It reports CI provider and job gaps, deploy target, Dockerfile, IaC and missing basics.
2. **Shape the pipeline** — default from [references/stages.md](references/stages.md): PR checks → preview (optional) → staging (auto on merge) → production (promotion of the same artifact).
3. **Set the gates** per stage — [references/gates.md](references/gates.md). Gates come from the other domains: tests (`test-strategy`), security (`secrets-and-deps`, dependency audit, secret scan), AI evals, PR rules (`collaboration`).
4. **Fill the pieces** — hand off: CI → `ci`; env/config → `environments`; hosting → `infrastructure-as-code`; signals → `observability`; deploy + rollback → `release-and-rollback`.
5. **Write DELIVERY.md** and add to the project's CLAUDE.md/AGENTS.md: `Delivery: docs/ops/DELIVERY.md — read before changing CI, deploys or infrastructure.`

House defaults: [references/defaults.md](references/defaults.md).

## Hard rules
- Build once, promote the same artifact (image digest / release bundle) from staging to production. Never rebuild for prod.
- Production deploys are reversible in minutes; if not, it's not ready.
- No deploy, migration, infra change or destructive command against production without the user's explicit go-ahead. The infra guard hook asks before the dangerous ones.
- Secrets never pass through logs, CI output or agent chat.

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log foundation/design "DELIVERY.md + CI"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
