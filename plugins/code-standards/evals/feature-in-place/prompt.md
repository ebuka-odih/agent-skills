---
description: New behaviour goes in the right module following existing patterns, with boundary tests and no leftovers.
tags: [code]
runs: 1
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Add the late-cancellation fee rule: cancelling 2 hours or more before class is free; cancelling less than 2 hours before costs 50% of the price paid; after the class has started it's 100%. Just the rule and its tests — no endpoint yet. (If running tests is blocked in this environment, say so rather than working around it.)
