---
name: backend
description: Entry point for building server-side code well — where business logic lives, how schema changes ship without downtime, how background jobs, queues, workers and schedulers stay correct under retries, crashes and deploys, and how calls to other services fail safely. Laravel and FastAPI (async SQLAlchemy, Alembic, arq/Celery/Postgres queues). Use when writing or reviewing backend code, endpoints, services, models, migrations, jobs, workers, cron/scheduled tasks or API clients; when the user says "backend", "add an endpoint", "migration", "queue", "job", "worker", "cron", "it hangs in production", "it sent twice", "retry storm"; or when loop.sh is in the build phase on server code.
---

# Backend (orchestrator)

`architecture` decides *what* the components are; this plugin says *how to build them* so they behave in production.

```
backend/skills/
├── backend/            ← you are here: read ARCHITECTURE, pick the stack guide, route
├── service-structure/  thin handlers → services → domain → repositories/adapters; transactions; errors
├── migrations/         expand → migrate → contract; locks, backfills, indexes, rollback
├── background-jobs/    idempotent jobs, retries with backoff, leases, dead letter, one scheduler, event loops
├── integrations/       outbound calls: timeouts, retries, circuit breakers, quotas, webhooks
├── concurrency/        idempotency keys, unique constraints, optimistic locking, atomic updates, locks
└── graceful-shutdown/  SIGTERM → drain → hand back work; grace periods; deploys that lose nothing
```
Outages and health checks → `devops:uptime`. Related: API shape → `architecture:api-design` · data model → `architecture:data-design` · secure coding → `security:secure-coding` · tests → `testing` · alerts → `devops:observability`.

## Steps
1. **Read** `docs/architecture/ARCHITECTURE.md` (components, data, async work) and house defaults [references/defaults.md](references/defaults.md).
2. **Stack guide** — [references/laravel.md](references/laravel.md) or [references/fastapi.md](references/fastapi.md).
3. **Route by the change**: new endpoint/feature → `service-structure`; schema change → `migrations`; anything async, scheduled or retried → `background-jobs`; any call to another system → `integrations`; money/messages/bookings/counters or "exactly once" → `concurrency`; workers, deploy config or long requests → `graceful-shutdown`.
4. **Check** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/backend-scan.sh" [dir]` (risky migrations, jobs without limits, HTTP without timeouts, unguarded schedulers); the hook flags the same while you write.
5. **Prove** — the failure path has a test (retry, crash mid-job, provider down, duplicate delivery), not only the happy path.

## Hard rules
- Handlers parse, authorise, call one service, shape the response — no business logic or SQL in routes/controllers.
- Every external call has a timeout; every job has a timeout, an attempt limit and backoff; every handler of a retried message is idempotent.
- Schema changes are backwards-compatible with the code that is still running.
- One scheduler fires each periodic task, in the process that is actually deployed.

## Hand-off (project loop)
`bash <product plugin>/scripts/loop.sh log build "backend: <what changed>"` then `loop.sh next`.
