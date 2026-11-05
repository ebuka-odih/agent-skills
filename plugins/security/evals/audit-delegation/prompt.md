---
description: A full-audit request routes to Cloudflare's security-audit skill, asks before installing it, and keeps output outside the repo.
tags: [security, fast]
runs: 1
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
Do a full security audit / pen test of this codebase.
