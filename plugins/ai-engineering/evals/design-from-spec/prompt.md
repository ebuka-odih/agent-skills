---
description: From a spec with AI requirements, writes AI.md + feature cards with tiers, fallbacks, evals and safety; picks Pydantic AI for the FastAPI stack.
tags: [ai, slow]
runs: 1
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Design the AI architecture for this project from the spec. Don't ask me questions — use sensible defaults and list what you assumed.
