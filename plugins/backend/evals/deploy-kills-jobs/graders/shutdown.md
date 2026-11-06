---
type: llm
weight: 4
---
PASS only if the agent: (1) handles SIGTERM in the worker (signal handler / event) so it stops claiming new jobs; (2) lets the in-flight job finish within a deadline and otherwise hands it back (release the lease / set status back to queued) instead of leaving it "running" until the lease expires; (3) sets `stop_grace_period` on the worker service to cover the longest import (≥ ~90 s, e.g. 120s) — and keeps the app's own deadline below it; (4) mentions or adds a way to verify (drill/test). FAIL otherwise.
