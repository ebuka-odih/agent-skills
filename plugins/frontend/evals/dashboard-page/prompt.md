---
description: Builds a dashboard page from shared patterns — header, filter bar with URL state, stat cards, data table, loading/empty/error states, tokens only.
tags: [frontend, slow]
runs: 1
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Build the Orders dashboard page in src/features/orders/OrdersPage.tsx using fetchOrders from ./api: three stat cards (revenue, orders, refunds), a search box and status filter, and a paginated table of orders. Don't install anything.
