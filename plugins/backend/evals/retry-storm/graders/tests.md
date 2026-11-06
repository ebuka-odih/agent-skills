---
type: llm
weight: 2
---
PASS if the agent added tests (e.g. tests/test_geocode.py) that prove: a failed row is not retried before next_attempt_at; a 402 pauses calls; attempts are bounded. FAIL if no tests or only happy-path tests.
