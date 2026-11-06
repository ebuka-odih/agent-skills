# Shutdown per runtime

| Runtime | On SIGTERM | Set |
|---|---|---|
| uvicorn | stops accepting, waits for open requests, runs lifespan shutdown | `--timeout-graceful-shutdown 20`; in lifespan: set `app.state.shutting_down = True` (readiness → 503), cancel + await background tasks, `await engine.dispose()`, close shared `httpx.AsyncClient` |
| gunicorn (+ uvicorn workers) | graceful worker stop | `--graceful-timeout 30` (and `--timeout` for hung workers) |
| Laravel `queue:work` | finishes the current job, then exits | `--timeout` < `retry_after`; deploy runs `php artisan queue:restart`; supervisor `stopwaitsecs` > longest job |
| Laravel Horizon | `horizon:terminate` waits for jobs | deploy: `php artisan horizon:terminate`; supervisor restarts it |
| arq | stops polling; running jobs get up to the timeout | `job_timeout`; `allow_abort_jobs`; jobs idempotent (they may rerun) |
| Celery | warm shutdown: finishes current tasks | `acks_late=True` + `task_reject_on_worker_lost=True` so killed tasks are redelivered; visibility timeout > longest task |
| Postgres queue worker | set `stopping`; don't claim; finish the current job within the grace; else `UPDATE jobs SET status='queued', lease_until=NULL WHERE id=:id AND locked_by=:me` | signal handler sets an `asyncio.Event`; loop checks it before each claim |
| asyncio pollers in the web app | cancelled at lifespan shutdown | `task.cancel(); await asyncio.gather(task, return_exceptions=True)` |
| Docker / compose | SIGTERM → wait `stop_grace_period` (default **10 s**) → SIGKILL | `stop_grace_period: 60s` for workers; `init: true` or exec-form CMD so PID 1 forwards signals |
| Kubernetes | endpoints removed while SIGTERM is sent (race) | `preStop: sleep 5–10`; `terminationGracePeriodSeconds` > app timeout; readinessProbe on `/readyz` |
| Dokploy / Swarm | like compose | `stop_grace_period` per service |

## Python worker loop shape
```python
stop = asyncio.Event()
loop.add_signal_handler(signal.SIGTERM, stop.set)
while not stop.is_set():
    job = await claim_one()            # never claim after stop is set
    if job is None:
        await asyncio.wait_for(stop.wait(), timeout=poll_seconds) if not stop.is_set() else None
        continue
    await run_with_deadline(job)       # on deadline: release the lease, don't mark failed
```
