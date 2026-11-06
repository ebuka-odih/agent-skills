---
type: llm
weight: 2
---
PASS if the agent added a test that runs the charge concurrently or simulates the race (threads/processes/two sessions, or a duplicate reference after a commit) and asserts exactly one charge and a non-negative balance — or clearly explains that SQLite can't show row-lock behaviour and the test must run on Postgres. FAIL if only sequential happy-path tests.
