---
description: Security review finds IDOR, SQL injection, mass assignment and missing webhook verification with file:line.
tags: [security, fast]
runs: 1
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---
Security-review the controller in the `resources` directory (`resources/InvoiceController.php`) before we merge. Answer in chat only.
