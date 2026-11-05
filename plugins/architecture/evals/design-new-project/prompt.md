---
description: Full Design-mode run writes ARCHITECTURE.md + ADRs following house defaults.
tags: [architecture, slow]
runs: 1
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
I'm starting a new project in this empty folder: a booking app for small yoga studios. Studio owners manage classes and instructors; members book and pay for classes on web and a mobile app. Each studio is a separate customer. 2 engineers, about 200 studios and 20k members in year one. Payments via Stripe. EU customers.

Design the system and write the architecture doc. Use the house defaults for anything I didn't say and don't ask me questions — just record what you assumed.
