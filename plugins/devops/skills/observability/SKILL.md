---
name: observability
description: Make production understandable — structured logs with request/tenant IDs and no PII, metrics per endpoint and job (rate, errors, duration), distributed traces with OpenTelemetry, error tracking, health endpoints, SLOs per user journey and alerts on burn rate routed to a human. Use when the user says "add logging", "monitoring", "metrics", "tracing", "alerts", "SLO", "why is prod slow", "we didn't know it was down", or when delivery-pipeline routes observability work. AI calls follow ai-engineering ai-ops.
---

# Observability

## Steps
1. **Logs** — structured JSON, one event per line, with `request_id`, `tenant_id`, `user_hash`, `route`, `duration_ms`, `status`. Correlate across services and queues by propagating the request/trace ID. No passwords, tokens, card numbers or unnecessary PII.
2. **Metrics** — RED per endpoint (Rate, Errors, Duration p50/p95/p99) and per job/queue (throughput, failures, lag/age of oldest message). Plus saturation: CPU, memory, DB connections.
3. **Traces** — OpenTelemetry auto-instrumentation (HTTP server/client, DB, queue); export to the chosen backend. Sample: 100% errors, ~10% of normal traffic to start.
4. **Errors** — error tracker (Sentry or similar) with release + environment tags; source maps for frontends.
5. **Health** — `/health` (process up) and `/ready` (DB, cache reachable) for load balancers and deploy checks.
6. **SLOs and alerts** — [references/slo.md](references/slo.md): one availability + one latency SLO per critical journey (from SPEC NFRs), alerts on error-budget burn rate, routed to a named channel/person.
7. **Record** in DELIVERY.md: where logs/metrics/traces live, dashboards, alert routes, on-call owner.

Stack notes: [references/stacks.md](references/stacks.md).

## Hard rules
- Alert on symptoms users feel (error rate, latency, failed jobs), not on every exception.
- Every alert has an owner and a runbook line ("what to check first").
- Logs and traces are subject to the same PII rules as the database (architecture `data-design`).
