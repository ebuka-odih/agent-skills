---
description: Adds an endpoint the right way — thin route, a service with the business rule and transaction, domain errors mapped once, DB-enforced uniqueness, tests at the service level.
tags: [backend]
runs: 1
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Add an endpoint to cancel a booking: patients can cancel up to 2 hours before the slot; staff can always cancel. Follow how this backend should be structured. Code is in app/.
