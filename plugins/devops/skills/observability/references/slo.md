# SLOs and alerting

## Define per critical journey
| Journey | SLI | SLO (30 days) | Source |
|---|---|---|---|
| Search | % of `/api/search` requests 2xx/3xx | 99.5% | load balancer / app metrics |
| Search | p95 latency of `/api/search` | < 800 ms | traces/metrics |
| Booking | % of booking attempts that complete | 99.0% | app events |

Start from SPEC NFRs (`NFR… p95 < 300 ms`). No NFR → propose one from current measurements and mark it `(assumed)`.

## Burn-rate alerts (multi-window)
| Severity | Condition | Action |
|---|---|---|
| Page | burning 2% of the monthly budget in 1 h (≈14× rate) | wake someone |
| Ticket | burning 10% in 3 days (≈1× rate) | fix this week |

## Every alert has
- an owner (person or rotation) and a channel a human reads,
- a one-line runbook: first dashboard/log query to check,
- a test: fire it once in staging to prove it reaches someone.

## Quiet alerts
Delete or downgrade alerts nobody acts on. Noise is how real outages get missed.
