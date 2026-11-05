# AI metrics and alerts

| Metric | Per | Alert when |
|---|---|---|
| Cost (USD) | feature · day | > 80% of daily budget; > 2× 7-day average |
| Calls | feature · hour | > 3× normal (abuse/loop) |
| p95 latency | feature | above card target for 15 min |
| Invalid-output rate | feature · model | > 2% |
| Fallback-model rate | feature | > 10% (primary unhealthy) |
| Non-AI fallback rate | feature | > 1% (users getting degraded answers) |
| 402 / 429 errors | provider | any 402 (credits); 429 > 1% |
| Steps per agent run | feature | p95 > max_steps − 1 (looping) |
| Eval score | feature | drop > 3 points vs last accepted run |
| User feedback (thumbs, edits, overrides) | feature | down-votes / edit rate rising week over week |

Dashboard: one row per feature with cost, calls, p95, invalid %, fallback %, last eval score.
