---
type: llm
weight: 3
focus: { source: file, path: src/features/orders/OrderStatusBadge.tsx }
---
The original badge hard-coded palette colours, arbitrary px values and an inline style for four statuses (paid, pending, failed, refunded). The project's globals.css defines semantic tokens (primary, muted, destructive, …) and the fix is expected to add success/warning tokens (checked separately).

PASS only if this file:
1. renders all four statuses through one component API — a cva variant map, a status → variant/class map, or the shadcn Badge with variants — not four hand-written class strings with palette colours;
2. uses semantic token classes (e.g. bg-success / text-success, bg-warning, bg-destructive or variant="destructive", bg-muted / text-muted-foreground) for the statuses;
3. has no Tailwind palette colours, hex values, arbitrary [Npx] values or inline style;
4. maps failed → destructive and refunded → a neutral token (muted/secondary/outline).
FAIL otherwise.
