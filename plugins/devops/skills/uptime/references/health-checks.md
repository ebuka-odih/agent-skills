# Health checks

| Probe | Answers | Checks | Used by | On failure |
|---|---|---|---|---|
| **Liveness** `/livez` (or `/health`) | is the process alive and not wedged? | nothing external; event loop responds | container restart policy, K8s liveness | restart the container |
| **Readiness** `/readyz` | can it serve traffic now? | DB `SELECT 1` (≤ 1 s timeout), cache ping, migrations applied; returns 503 while starting or shutting down | load balancer, K8s readiness, deploy gates, uptime monitor | stop routing to it (no restart) |
| **Startup** | finished booting? | same as readiness | K8s startupProbe | wait |

## Per stack
| Stack | How |
|---|---|
| Laravel 11+ | `->withRouting(health: '/up')` (built-in; dispatches `DiagnosingHealth` — listen to add DB checks) |
| FastAPI | `@app.get("/livez")` → `{"ok": true}`; `@app.get("/readyz")` runs `await session.execute(text("SELECT 1"))` with a timeout, returns 503 on failure or when `app.state.shutting_down` |
| Node/Express | `app.get('/livez')`, `app.get('/readyz')` likewise |
| Docker | `HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl -fsS http://localhost:8000/livez || exit 1` (or `wget -qO-`; python one-liner if no curl) |
| compose / Dokploy | `healthcheck:` per service + `restart: unless-stopped`; `depends_on: { db: { condition: service_healthy } }` |
| K8s | liveness → `/livez`, readiness → `/readyz`, `terminationGracePeriodSeconds` ≥ longest request/job drain |

## Rules
- Health endpoints are unauthenticated, cheap, not cached, excluded from rate limits and access logs noise.
- Readiness flips to 503 as the first step of shutdown, so traffic drains before the process stops (see `backend` graceful shutdown).
- Return JSON with per-check status for humans; the status code is what machines read.
