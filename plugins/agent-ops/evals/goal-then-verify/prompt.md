---
description: Agent writes GOAL.md before working, verifies with evidence, and the session is logged.
tags: [agent-ops]
runs: 1
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
In this empty folder, create `str.js` exporting a `slugify(text)` function (lowercase, spaces and punctuation become single hyphens, no leading/trailing hyphens) and a `str.test.js` that tests it with Node's built-in test runner (`node --test`). Make sure it actually works.
