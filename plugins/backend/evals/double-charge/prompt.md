---
description: Fixes double charging under retries/double clicks with an idempotency key, an atomic balance update and a parallel test — not just an application-level check.
tags: [backend]
runs: 1
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Some customers get charged twice when they double-click "Buy credits" or the mobile app retries after a timeout, and once two charges at the same moment took a wallet below zero. Fix it in app/ and prove it.
