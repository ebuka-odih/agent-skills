---
name: graceful-shutdown
description: Let deploys and restarts happen without losing work — on SIGTERM stop taking new requests and jobs, flip readiness to 503, finish or hand back in-flight work within a grace period (release leases, re-queue), close pools cleanly, and size container/orchestrator grace periods above the longest request or job. uvicorn/gunicorn, Laravel queue workers and Horizon, arq, Celery, Postgres queues, Docker and Kubernetes. Use when the user says "deploy killed a job", "jobs lost on restart", "502 during deploy", "SIGTERM", "zero-downtime deploy", "worker restart", or when writing a worker loop or deploy config.
---

# Graceful shutdown

Every deploy sends **SIGTERM**, waits a grace period, then **SIGKILL**. Whatever isn't finished or handed back by then is lost or half-done.

**Output:** each process type with its shutdown sequence, grace period and a test (or a manual drill) that a deploy mid-job loses nothing.

## Steps
1. **List process types** (web, each worker, scheduler) and the longest request/job each runs.
2. **Shutdown sequence per process** — [references/runtimes.md](references/runtimes.md): readiness → 503; stop accepting/claiming; finish in-flight work up to a deadline; hand back the rest (release lease / requeue / `nack`); close pools; exit 0.
3. **Grace periods line up**: app's own shutdown timeout < container `stop_grace_period` / K8s `terminationGracePeriodSeconds` < job lease. Longer jobs checkpoint and resume instead of needing a long grace.
4. **Load balancer drains first** — readiness 503 (and a short pre-stop delay on K8s) so no new requests land on a stopping instance.
5. **Drill it** — start a long job, deploy/restart, check it finished or reran exactly once.
6. **Check** — `backend-scan.sh` flags worker loops with no stop condition and worker services with Docker's default 10 s grace.

## Hard rules
- Workers stop *claiming* the moment SIGTERM arrives; they never start a job they can't finish in the grace period.
- Unfinished work is handed back explicitly (lease released, message nacked), not left for a timeout to discover.
- `while True:` worker loops check a stop flag; background asyncio tasks are cancelled and awaited in the lifespan shutdown.
- Deploys restart queue workers (`queue:restart` / `horizon:terminate`) so they run the new code.
