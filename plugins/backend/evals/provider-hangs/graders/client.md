---
type: llm
weight: 4
focus: { source: file, path: app/crm.py }
---
Planted: no timeouts (requests has none → hangs), a POST retried 5 times with no backoff (duplicate notes), bare except, env read per call.

PASS only if app/crm.py: sets connect+read timeouts on every call (via one client/session); retries only idempotent calls (GET) with backoff, and does NOT blindly retry the POST (or uses an idempotency key); maps failures to specific errors instead of bare except; reads config once. FAIL otherwise.
