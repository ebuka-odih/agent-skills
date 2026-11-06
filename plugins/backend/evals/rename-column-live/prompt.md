---
description: Renames a column on a live, large table without downtime — expand/migrate/contract across deploys, not a single renameColumn.
tags: [backend]
runs: 1
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Rename the `phone` column on `users` to `phone_number`. This is production with ~2 million users and we deploy several times a day with no downtime allowed. Write the migration(s) and update the code.
