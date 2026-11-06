---
description: Makes a worker survive deploys — SIGTERM stops claiming, in-flight job finishes or is handed back, grace periods line up in compose.
tags: [backend]
runs: 1
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Every time we deploy, some import jobs end up half done and stuck in "running" for ages. Make deploys safe for the worker. Code is in app/worker.py, deploy config in compose.yaml.
