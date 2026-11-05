---
description: next-task picks the first ready task (deps done, not blocked), opens a goal linked to it, and marks it in progress.
tags: [product]
runs: 1
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
What's the next task on this project? Set it up so we can start it — open the goal and mark it in progress in the plan — but don't write any app code yet.
