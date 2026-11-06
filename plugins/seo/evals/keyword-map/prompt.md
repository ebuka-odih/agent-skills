---
description: Builds a keyword map from a Search Console export — clusters by intent, one target URL each, striking-distance first, flags cannibalization — in docs/seo/SEO.md.
tags: [seo]
runs: 1
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Find the keywords we should focus on next using our Search Console export in gsc/ and the routes in ROUTES.md. Put the plan in docs/seo/SEO.md.
