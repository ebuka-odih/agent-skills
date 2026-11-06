---
description: Fixes raw colours, arbitrary values and inline styles by adding status tokens and a cva variant component.
tags: [frontend]
runs: 1
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
The order status badge in src/features/orders/OrderStatusBadge.tsx looks off next to the rest of our shadcn dashboard and breaks in dark mode. Make it consistent with our design system.
