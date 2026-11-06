# Runners — pick and place

| Runner | Good for | Watch out |
|---|---|---|
| Laravel queue (Redis/Horizon, database) | Laravel apps | `retry_after` > longest `$timeout`; one `schedule:work`; Horizon supervisors per queue |
| arq (Redis, asyncio) | async FastAPI apps | needs a **deployed** `arq` worker process; `cron_jobs` only fire in that worker |
| Celery (+ beat) | heavy/CPU work, many queues | exactly one beat; `acks_late` + visibility timeout |
| Postgres queue (SKIP LOCKED) | one-DB apps, transactional enqueue | see postgres-queue.md; vacuum/index the jobs table |
| In-process asyncio task (lifespan) | light pollers in a single-instance app | dies with the web process; runs N times with N replicas → advisory lock; must use the app's loop and engine |
| FastAPI `BackgroundTasks` | tiny fire-and-forget after a response | lost on crash/deploy — never for money, messages or anything that must happen |

## Where does it actually run?
Before adding a cron/worker: read the deploy config (Dockerfile CMD, compose services, Procfile, Dokploy/K8s manifests). A cron registered for a worker that isn't deployed never fires; adding a second poller next to an existing one double-processes rows. One firing path per task — remove the other.

## Event loops and threads (Python)
- An `AsyncEngine`/pool, `AsyncClient` or Redis connection is bound to the loop it was first used on. A thread with its own `asyncio.run()` using the app's engine hangs or raises "attached to a different loop".
- Run pollers as `asyncio.create_task` in the app lifespan (cancel on shutdown), or in a separate process that creates its own engine.
- Sync libraries in async code: `asyncio.to_thread`.
