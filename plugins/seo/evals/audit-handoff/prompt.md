---
description: Turns a live crawl report into a prioritised handoff grouped by root cause with evidence and fixes.
tags: [seo, fast]
runs: 1
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
---
We crawled our live site; the output is in audit/crawl.txt and our nginx config is in nginx.conf. Write the fix list for the developer in audit/HANDOFF.md, most important first.
