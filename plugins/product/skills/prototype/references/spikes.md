# Spikes — tech, data and AI

A spike is a script, not an app. It prints the number the card asked for.

## Layout
```
proto/<slug> branch
└── prototypes/<slug>/
    ├── README.md        card copy + run command + result
    ├── spike.py|ts|sh   the one script
    ├── sample/          inputs (real, anonymised if personal)
    └── out/             results: results.csv, summary.txt
```

## Patterns
| Spike | Script does | Prints |
|---|---|---|
| API capability | call the endpoint with 10–30 real inputs; record status, latency, fields present | success rate, p50/p95 latency, missing fields, quota/cost per 1k |
| Library fit | implement the hardest case only (not the easy 80%) | does/doesn't, code size, gotchas |
| Performance | generate production-size data (×10 the launch estimate); time the critical query/operation | p50/p95 vs budget, where time goes (EXPLAIN, profiler) |
| Data sufficiency | count real records per bucket the product needs | coverage table; % of buckets over threshold |
| AI quality | run prompt over 20–50 labelled examples; score with a rubric or exact match | accuracy, failure categories, tokens, cost/1k, latency |

## Reading the result
- Beats success → **keep**: write the decision (ADR if it shapes the system), plan the real task.
- Between success and kill → **change**: adjust scope/approach in SPEC (change log), maybe a second card.
- Hits kill → **kill**: record why; the SPEC requirement changes or goes to non-goals.
- Ran out of time → that's data: the approach is harder than assumed; usually **change**.
