# Layers

| Layer | Does | Must not | Laravel | FastAPI |
|---|---|---|---|---|
| Handler | parse + validate input, authorise, call one service, map result/errors to the response | business rules, SQL, outbound calls, loops over data | Controller + FormRequest + Resource | router function + Pydantic models + `Depends` |
| Service (use case) | orchestrate one action: load, check rules, change, persist, enqueue after commit | know about HTTP, read env vars, hold state between calls | `app/Actions/*`, `app/Services/*` | `app/services/*` functions or classes |
| Domain | rules and calculations on plain data (pure, fast tests) | I/O | value objects, enums, model methods without queries | dataclasses/Pydantic, pure functions |
| Repository / adapter | queries, external APIs, files, queues | business decisions | Eloquent scopes/query objects, API client classes | SQLAlchemy queries in repo modules, httpx clients |

Dependency direction: handler → service → domain; service → repository/adapter interfaces. Nothing points back up.

## Smells → fix
| Smell | Fix |
|---|---|
| Controller > ~40 lines or with `if` business branches | move to a service/action |
| Same rule checked in two endpoints | one service; both call it |
| Service catches HTTP exceptions or returns JSON responses | raise domain errors; handler maps |
| Query in a loop (N+1) | eager load / one set-based query |
| `now()` / `datetime.now()` scattered in rules | inject a clock (`now` param) so tests can freeze time |
| Check-then-insert race ("is the slot free?" then insert) | unique constraint + catch the violation, or `SELECT … FOR UPDATE` inside the transaction |
