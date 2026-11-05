---
type: llm
weight: 4
focus: { source: file, path: tests/test_fees_properties.py }
---
PASS only if the file:
1. uses Hypothesis (`@given` with strategies) — not just a hand-written loop;
2. states at least three real invariants from the spec, e.g. 0 <= fee <= price; fee is 0 when cancelled >= 2 h before; fee == price once started; cancelling later never lowers the fee (monotonic); fee is price // 2 in the < 2 h window;
3. generates timezone-aware datetimes (e.g. `st.datetimes(timezones=...)`) and tests that naive datetimes or negative prices raise ValueError;
4. does not reimplement the fee function's logic wholesale as the oracle;
5. keeps or adds explicit examples for the 120-minute boundary (`@example` or a separate test).
FAIL if 1, 2 or 3 is missing.
