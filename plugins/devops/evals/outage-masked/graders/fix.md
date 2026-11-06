---
type: llm
weight: 4
---
PASS only if the agent: (1) changes nginx so backend 5xx/timeouts are answered with 503 (+ Retry-After), not the 200 index.html shell; (2) adds liveness/readiness health endpoints to the FastAPI app (readiness checking dependencies, liveness not); (3) adds container healthchecks and restart policies in compose; (4) sets up or specifies external uptime monitoring with alerts to a human (home, a deep page, health endpoint; a heartbeat for background work is a bonus). FAIL if any of 1–3 is missing.
