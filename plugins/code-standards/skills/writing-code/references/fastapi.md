# FastAPI / Python

## Where things go
| Thing | Location | Notes |
|---|---|---|
| HTTP entry | `app/api/v1/endpoints/<area>.py` (routers) | Thin: deps → validate (Pydantic) → call service → response model |
| Request/response models | `app/schemas/<area>.py` (Pydantic v2) | `response_model=` on every route |
| Business logic | `app/services/<area>.py` or `app/application/<area>/` | Pure functions/classes; no FastAPI imports |
| Data access | `app/models/` (SQLAlchemy 2), repositories/queries per area | Async sessions via dependency |
| Dependencies | `app/api/deps.py` (`Depends`) | DB session, current user, tenant |
| Settings | `app/core/config.py` (`pydantic-settings`) | One `settings` object; no `os.environ` elsewhere |
| Background work | worker/queue module (arq, Celery, DB queue) | Idempotent jobs |
| AI | `app/ai/` or `app/agents/` per AI.md | See ai-engineering `ai-stack` |

## Conventions
- Type hints everywhere; `from __future__ import annotations`; Pydantic models for anything crossing a boundary.
- `async def` end to end when the DB driver is async; never call blocking I/O in async routes (use `run_in_threadpool`).
- Errors: raise domain exceptions in services, map to `HTTPException` in one exception handler.
- Timezone-aware datetimes (`datetime.now(UTC)`).
- Imports at the top; no try/except around imports that silently disables features.

## Commands (detected by project-commands.sh)
`ruff format` · `ruff check` · `mypy` or `pyright` · `pytest -q`.

## Tests
`pytest` + `httpx.AsyncClient`/`TestClient` against the app; dependency overrides (`app.dependency_overrides`) for DB/auth; factories or fixtures; `respx`/`pytest-httpx` for outbound HTTP; Pydantic AI `TestModel` for agents.

## Never
`print()` for logging · bare `except:` / `except Exception: pass` · mutable default args · module-level DB sessions.
