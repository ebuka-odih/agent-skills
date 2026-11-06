---
description: Sets up page-level browser checks (ui-check config + CI workflow) for the key templates, both themes and phone width, gating on serious/critical axe and sideways scroll.
tags: [frontend]
runs: 1
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
We just fixed a batch of accessibility and mobile layout bugs on our site. Add browser checks to CI so they can't slip back. Don't install anything; just add the files.
