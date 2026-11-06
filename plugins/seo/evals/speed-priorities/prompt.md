---
description: Reads a PageSpeed Insights result — judges by field p75 Core Web Vitals, names the failing metric, ranks fixes by savings, and routes implementation.
tags: [seo, fast]
runs: 1
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
Is our homepage fast enough for Google? The PageSpeed Insights API response is saved in psi/home.json. Tell me what to fix first. Answer in chat.
