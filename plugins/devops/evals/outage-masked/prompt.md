---
description: Makes outages visible and harmless — upstream 5xx become 503 + Retry-After (not the 200 app shell), health endpoints and container healthchecks exist, external monitoring is set up.
tags: [devops]
runs: 1
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Our API was down for two days last month and we only noticed when traffic in Google Search Console had collapsed. Make sure the next outage is noticed fast and does less damage. Config is in web/nginx.conf, compose.yaml and app/.
