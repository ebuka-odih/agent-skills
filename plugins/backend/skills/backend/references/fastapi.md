# FastAPI (async SQLAlchemy 2, Alembic, Pydantic)

| Concern | Use | Notes |
|---|---|---|
| Handlers | `APIRouter` endpoint → `Depends(get_session)` + service function | Pydantic request/response models; no SQL in endpoints |
| Domain logic | `app/services/*` (or `application/` use cases) taking `AsyncSession` + typed input | pure helpers in `domain/` |
| Sessions | one `AsyncSession` per request via dependency; `async with session.begin():` in the service | never share a session across tasks; `expire_on_commit=False` if returning ORM objects |
| Event loop | background work as `asyncio` tasks on the app's loop (lifespan) **or** a separate worker process with its **own engine** | an async engine/pool created on one loop hangs or errors on another loop/thread |
| Blocking calls | `await asyncio.to_thread(fn)` / `run_in_executor` | never `requests` or `time.sleep` inside `async def` |
| Errors | domain exceptions + `@app.exception_handler` → problem+json | don't leak stack traces |
| Jobs | arq (Redis) / Celery / Dramatiq, or a Postgres queue (`FOR UPDATE SKIP LOCKED` + leases) | see background-jobs; `BackgroundTasks` only for small, loss-tolerant work |
| Scheduler | arq `cron_jobs` / Celery beat / one loop in the worker — in a process that is deployed | one scheduler; advisory lock if several replicas run it |
| Migrations | Alembic autogenerate **reviewed by hand**; `op.create_index(..., postgresql_concurrently=True)` inside `with op.get_context().autocommit_block():` | `SET lock_timeout` at the start of risky migrations |
| HTTP client | one shared `httpx.AsyncClient(timeout=httpx.Timeout(10, connect=3))` per app (lifespan) | `requests` has **no default timeout**: always pass `timeout=` |
| Settings | `pydantic-settings` `Settings` loaded once | |
| Tests | pytest-asyncio, a real Postgres for Postgres SQL (SKIP LOCKED, ON CONFLICT, advisory locks), `respx`/`httpx.MockTransport` for outbound | freeze time for backoff tests |
