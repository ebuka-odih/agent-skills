---
description: Check mode catches a module-boundary violation with file:line.
tags: [architecture, fast]
runs: 2
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---
There's a project in the `resources` directory. Someone just added `app/Billing/InvoiceService.php`. Check whether this change fits our architecture doc (`docs/architecture/ARCHITECTURE.md` in that project). Report in chat only.
