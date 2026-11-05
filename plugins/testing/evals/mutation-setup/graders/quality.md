---
type: llm
weight: 4
focus: trace
---
The project uses Pest 3. The existing tests are weak: no test at exactly 120 minutes, at 0/negative minutes, or for the exact 50% amount.

PASS only if ALL hold:
1. Uses Pest's built-in mutation testing (`--mutate`) with `covers(LateCancelFee::class)` or `mutates(...)` in the test file (Infection is acceptable as an alternative if justified).
2. Adds tests that would kill boundary mutants: exactly 120 minutes (free), 119 minutes (half, exact amount like 500 of 1000), 0 or negative minutes (full price), and an odd price for intdiv rounding — or at least three of these.
3. Gives a CI command with a minimum score (e.g. `--min=80`) and scopes it to the billing code / changed files rather than the whole codebase.
4. Does not claim it ran mutation testing.
FAIL otherwise.
