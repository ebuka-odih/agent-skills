---
description: next-task step 0 turns a multi-request chat message into separate, correctly formed plan tasks (and a requirement when none covers it) before any code.
tags: [product]
runs: 1
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Two things for the book club app: organisers should be able to remove a candidate book before the vote closes, and members should see the live vote tally while voting is open. Don't build them yet — just get them into the plan so we can do them one at a time.
