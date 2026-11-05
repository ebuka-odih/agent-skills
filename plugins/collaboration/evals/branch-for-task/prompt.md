---
description: Starts the next ready plan task on a correctly named branch.
tags: [collaboration]
runs: 1
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
Start work on the next task in the plan: just create the branch for it. Don't write any code. If git commands are blocked in this environment, don't work around it — show me the exact command you would run.
