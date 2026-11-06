---
description: Audits a built site in dist/ and finds the planted technical SEO problems (robots block, relative canonical, duplicate titles, two h1s, broken JSON-LD, noindex page in sitemap).
tags: [seo, fast]
runs: 1
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
We launch tomorrow. The production build is in dist/ and the site will live at https://example.com. Check it for SEO problems and tell me what to fix, most important first. Don't change any files.
