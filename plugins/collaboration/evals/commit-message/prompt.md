---
description: Commits only the task's files with a Conventional Commit message referencing the task.
tags: [collaboration]
runs: 1
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
I finished the voting change on this branch. Commit it for me (don't push). If git commands are blocked in this environment, don't work around it — show me the exact `git add` and `git commit` commands (with the full message) you would run.
