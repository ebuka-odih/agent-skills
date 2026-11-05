# Test levels

| Level | Tests | Speed | Use for |
|---|---|---|---|
| **Unit** | one function/class, no I/O | ms | pure logic with many cases: pricing, parsing, rules, date maths |
| **Feature / integration** | module through its entry point with real test DB | 10–200 ms | endpoints, actions/services, jobs, policies — **the default** |
| **Contract** | API/schema compatibility between services | fast | split services, public APIs (OpenAPI diff, Pact) |
| **End-to-end** | real browser/app against a running stack | seconds | 3–10 critical journeys (sign-up, checkout, core flow) |
| **AI evals** | model behaviour on a golden set | slow/$ | AI features — see ai-engineering `ai-evals` |

## Coverage target
Not a percentage. Every acceptance criterion, every failure path in error-handling, every bug ever fixed. Line coverage is a smoke alarm for untested files, not a goal.

## Case checklist for a function or endpoint
- typical input · empty / null · boundary (0, 1, max, exactly-at-cutoff) · wrong type/format · unauthorised · not found · conflict/duplicate · external dependency fails/times out
