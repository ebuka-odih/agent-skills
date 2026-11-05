---
description: Writes deterministic boundary tests from a spec rule, no network or real clock.
tags: [code]
runs: 1
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Write]
---
`app/fees.py` implements our late-cancel fee. Write pytest tests for it into `tests/test_fees.py`. Don't modify fees.py. (You can't run them here — just write them.)
