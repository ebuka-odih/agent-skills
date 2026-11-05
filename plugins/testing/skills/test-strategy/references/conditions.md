# Conditions → techniques

Base layer for **every** behaviour change: unit tests for pure logic + feature/integration tests at the module boundary (code-standards `testing`). The rows below are **additions**.

| Condition (any of) | Add | Why | Not when |
|---|---|---|---|
| Pure logic with many possible inputs: money, fees, tax, discounts, dates/time zones, parsing, validation, serialisation round-trips, sorting/ranking | **Property-based** | Finds the edge case you didn't think of | Simple mapping/CRUD with 2–3 cases |
| Business-critical rule: payments, refunds, pricing, permissions/authorization, tenancy, quotas, security checks | **Mutation testing** on the changed files (MSI gate) | Proves the tests fail when the rule breaks | Glue code, generated code, whole legacy codebase at once |
| Tests exist but you're not sure they assert anything ("100% coverage, still bugs") | **Mutation testing** (one-off report) | Coverage ≠ checking | — |
| HTTP endpoint added/changed | Feature test (base) + **contract** check if an OpenAPI/schema exists | Clients break on shape changes | Internal-only endpoint with one in-repo caller |
| Public/partner API, or a service called by another service/team | **Contract testing** (OpenAPI diff in CI; Schemathesis fuzz; Pact for consumer-driven) | Catches breaking changes before deploy | Monolith-internal calls |
| A SPEC journey (`J1…`) marked must, or checkout/sign-up/payment flow touched | **E2E** for that journey only | Proves the pieces work together in a browser | Every edge case — those belong in feature tests |
| NFR latency/throughput target (`p95 <`, `rps`) on a touched path, or a new heavy query/endpoint | **Load test** (k6) against staging | Performance regressions don't show in unit tests | No target in spec and not a hot path |
| UI component/page added or changed | Component test (Testing Library) + **accessibility** check (axe) | Keyboard/screen-reader users | Pure styling tweak with no structure change → a11y lint only |
| Shared design-system component or brand-critical page | **Visual regression** (Playwright screenshots) | Pixel changes slip through other tests | Pages with lots of dynamic data (flaky) |
| DB migration | Migration test: up → down → up on a copy; data backfill test | Zero-downtime rules | Pure additive nullable column |
| AI feature / prompt / model change | **AI evals** (ai-engineering `ai-evals`) | Behaviour is statistical | — |
| Bug fix | Regression test that fails before the fix (base) | Bugs come back | — |
| Concurrency: double submit, webhooks retried, queue workers | Idempotency/race test (parallel requests, duplicate events) | Shows up only under load | Single-user admin actions |
| Flaky test found | Quarantine + fix (code-standards testing) | Trust in the suite | — |

## Proportionality examples
| Change | Plan |
|---|---|
| Rename a button label | Update the existing component/feature test. Nothing else. |
| New `late_cancel_fee()` + `POST /bookings/{id}/cancel` | Unit + property tests for the fee; feature tests for the endpoint (auth, 2 h boundary); mutation on `fees` (MSI ≥ 80%); contract diff if OpenAPI exists |
| New checkout page | Component + a11y; E2E for the checkout journey; visual snapshot if design-system; load test only if SPEC has a target |
