---
description: Check mode finds planted AI-architecture violations with file:line.
tags: [ai, fast]
runs: 1
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---
In the `resources` directory there's a project with an AI architecture doc at `docs/ai/AI.md`. Someone added `app/ai/summarise_reviews.py`. Review that file against our AI architecture. Report in chat only.
