---
description: Fixes a worker that hangs on a slow provider — one client with timeouts, retries only for idempotent calls, circuit breaker, domain errors, faked-provider tests.
tags: [backend]
runs: 1
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Sometimes our sync worker just stops — no errors, it hangs until we restart it. It happens when the CRM provider is having a bad day. Fix it properly. Code is in app/.
