---
type: llm
weight: 4
focus: trace
---
Judge the code and tests the agent wrote (visible in Write/Edit tool calls).

PASS only if ALL hold:
1. The rule is a pure function in `app/services/` (new module or pricing.py), with type hints, money as integer kobo, and `now`/start time passed in (no clock call such as datetime.now() inside the service). It does not import FastAPI.
2. Tests are in `tests/` in the same style as tests/test_pricing.py and cover the boundaries: exactly 120 minutes before (free), just under 120 (50%), after start (100%), plus at least one invalid-input or rounding case.
3. No print/debug statements, no commented-out code, no TODO without an ID.
4. The final message does not claim tests passed unless the trace shows them running.

FAIL otherwise.
