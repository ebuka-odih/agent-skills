---
name: release-and-rollback
description: Ship to production so any release can be undone in minutes — deploy strategy (rolling, blue/green, canary), health checks, database migrations that stay backward compatible, feature flags, a release checklist, a written rollback plan, and what to do when a deploy or migration fails in production. Use when the user says "deploy to production", "release", "rollback", "the deploy broke prod", "migration failed in prod", "feature flag", "canary", or when delivery-pipeline routes release work.
---

# Release and rollback

## Before a release
1. Fill [templates/RELEASE.md](templates/RELEASE.md) for anything beyond a routine deploy: what changes, migrations, flags, risk, **rollback steps**, verification.
2. Migrations follow expand → migrate → contract ([references/migrations.md](references/migrations.md)): the previous app version must still work after this release's migrations run.
3. Risky behaviour ships dark behind a feature flag; turn on gradually.

## Deploy
| Strategy | When |
|---|---|
| Rolling + health checks | default |
| Blue/green | risky releases, need instant switch-back |
| Canary (1–5% → 25% → 100%) | high traffic, behaviour risk; needs metrics per version |

Watch for 15–30 min: error rate, p95 latency, failed jobs, SLO burn (observability).

## When production breaks
Follow [references/incident.md](references/incident.md). Order: **stop the bleeding (rollback / flag off) → communicate → diagnose → fix forward → write it up.** Never run destructive "fixes" (`migrate:fresh`, `DROP`, `reset --hard` on prod data) — the infra guard hook asks before these, and the answer is almost always no.

## Hard rules
- The rollback is written before the deploy, and it's tested on staging for risky releases.
- Rolling back code must not require rolling back the schema (that's what expand/contract buys you).
- Production data is never deleted to make a migration pass; take a backup first and fix forward.
- Deploys need the user's go-ahead; agents prepare, humans approve.

## Hand-off (project loop)
After a milestone ships and smoke checks pass, set its line in `docs/plan/PLAN.md` to `status: released` and log it: `bash <product plugin>/scripts/loop.sh log release "M<n> released · next: operate/evolve"`. The loop then moves the project to operate/evolve.
