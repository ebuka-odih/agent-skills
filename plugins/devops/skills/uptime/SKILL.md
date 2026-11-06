---
name: uptime
description: Make outages short, visible and harmless — fail with the right status (503 + Retry-After, maintenance mode) instead of 200 pages that look fine, real 404s instead of soft-404 app shells, liveness vs readiness health checks, container healthchecks and restart policies, graceful degradation when a dependency is down, and external uptime monitoring that pages someone within minutes. Use when the user says "the site went down", "outage", "uptime", "health check", "maintenance mode", "503", "Google dropped our pages after downtime", "monitoring", "status page", or before the first public release.
---

# Uptime and outage behaviour

An outage costs twice: users can't work, and crawlers or clients **record what they saw**. A backend error served as `200 + empty page` tells Google the page is empty; a `503 + Retry-After` tells it to come back.

**Output:** health endpoints, correct failure responses at the edge, container health/restart config, external monitors with alerts, and a short "when it breaks" section in `docs/ops/DELIVERY.md`.

## Steps
1. **Scan** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/uptime-scan.sh" <repo> [--url https://site]`: masked 5xx, soft 404s, missing health endpoints, containers without healthcheck/restart, servers without a graceful timeout; with `--url`, live probes of health and 404 behaviour.
2. **Fail correctly** — [references/fail-correctly.md](references/fail-correctly.md): the status each failure must produce at the proxy, app and CDN, and how maintenance mode works per stack.
3. **Health checks** — [references/health-checks.md](references/health-checks.md): liveness (process alive, no dependencies) vs readiness (can serve: DB, cache) vs startup; wire them into Docker/compose/K8s/Dokploy and the load balancer.
4. **Degrade, don't die** — per dependency, decide: fail the request, serve cached/stale, hide the feature, or queue the work (`backend:integrations` for timeouts and circuit breakers).
5. **Monitor from outside** — [references/monitoring.md](references/monitoring.md): synthetic checks on home, one deep page per template, the health endpoint and the sitemap, from 2+ regions, alerting a human within 5 minutes; record each outage's start/end.
6. **After an outage** — `seo:search-console` drop diagnosis and recovery steps; incident notes via `release-and-rollback`.

## Hard rules
- Never turn an upstream 5xx into a 200: the user-facing fallback page keeps the 5xx status (503 + `Retry-After`).
- Unknown URLs return 404, even in SPAs with server-rendered or prerendered pages.
- Liveness never checks dependencies (a DB blip must not restart every container); readiness does.
- Every outage pages a human; no outage is discovered from analytics days later.
