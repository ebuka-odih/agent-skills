---
release: vX.Y.Z / <git sha>
date: YYYY-MM-DD
owner: <name>
risk: low | medium | high
---

# Release <version>

## What changes
- <PRs / tasks (T…) / requirements (R…)>

## Migrations
| Migration | Expand/migrate/contract | Backward compatible with previous app? | Down / forward-only |
|---|---|---|---|

## Flags
| Flag | Default in prod | Rollout plan |
|---|---|---|

## Pre-checks
- [ ] Staging deployed with this artifact, smoke E2E green
- [ ] Backup/snapshot taken (if migrations)
- [ ] Alerts and dashboards open

## Deploy steps
1. <command / button>

## Verify (15–30 min)
- [ ] Error rate ≤ baseline · p95 ≤ SLO · no failed jobs spike
- [ ] <journey-specific check>

## Rollback
1. <redeploy previous artifact sha … / flag off>
2. <migrations: none needed because expand-only — or exact steps>
Trigger: <error rate > x% for 5 min, or …>
