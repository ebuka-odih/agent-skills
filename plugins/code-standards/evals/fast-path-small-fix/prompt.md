---
description: A small, clearly specified fix takes the fast path — one regression test, the smallest change, module tests run — without GOAL.md, new docs or extra helpers.
tags: [code-standards, fast]
runs: 1
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
`format_price(0.5)` in app/money.py returns "₦0.5" but should return "₦0.50" — prices always show two decimals. Fix it.
