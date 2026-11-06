---
description: Diagnoses and fixes a retry storm — due-query ignoring next_attempt_at and a quota error retried every cycle — with backoff, a pause window and tests.
tags: [backend]
runs: 1
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Our logs show the geocoding worker calling the provider ~20 times a minute for the same failed addresses, and the provider now answers 402 "insufficient credit". Fix it and add tests. Code is in app/.
