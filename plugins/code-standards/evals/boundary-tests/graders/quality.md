---
type: llm
weight: 4
focus: { source: file, path: tests/test_fees.py }
---
PASS only if the tests:
1. cover exactly 2 hours before (fee 0), just under 2 hours (50%), exactly at start (100%) and after start (100%);
2. cover invalid input: negative price and naive datetimes both raise ValueError;
3. cover odd-kobo rounding for 50% (e.g. 101 → 50) or another rounding check;
4. use fixed timezone-aware datetimes (no datetime.now() / real clock, no sleeps, no network);
5. have names describing behaviour, one behaviour per test (parametrize is fine).
FAIL if any boundary in (1) or the naive-datetime case is missing.
