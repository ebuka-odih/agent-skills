---
type: llm
weight: 4
focus: { source: file, path: app/geocode.py }
---
Bugs planted: `Store.due` ignores `next_attempt_at` (failed rows retried every 5 s cycle) and a 402 (insufficient credit) is treated like any error.

PASS only if app/geocode.py:
1. makes the due query respect `next_attempt_at` (failed rows wait for their retry time);
2. treats 402/quota as "pause the provider for a window" (no calls during the window; rows not burned through attempts), distinct from transient 5xx/timeouts;
3. bounds attempts (max attempts → a terminal/dead state with the reason);
4. keeps backoff (ideally with jitter/cap).
FAIL otherwise.
