---
type: llm
weight: 4
focus: { source: file, path: TEST_PLAN.md }
---
The branch adds a late-cancel fee function (app/services/fees.py), a cancel endpoint (FastAPI), and a cancel dialog UI. SPEC has journey J2 (cancel), R7 with an exact 120-minute boundary, NFR1 (endpoint p95 < 300 ms at 30 rps) and NFR2 (WCAG 2.2 AA).

PASS only if the plan:
1. includes unit tests with the exact 120-minute boundary and feature/integration tests for the endpoint (incl. auth/not-found or invalid cases);
2. adds property-based tests for the fee function AND mutation testing scoped to the fee/critical code (not the whole codebase);
3. adds a load test (k6 or similar) tied to NFR1, run on staging/nightly rather than every commit;
4. adds an accessibility check (axe or similar) for the dialog tied to NFR2;
5. adds at most a small number of E2E tests (e.g. the J2 cancel journey), not E2E for every case;
6. says where/when each technique runs (commit / PR / nightly) or gives thresholds.
FAIL if any of 1–4 is missing.
