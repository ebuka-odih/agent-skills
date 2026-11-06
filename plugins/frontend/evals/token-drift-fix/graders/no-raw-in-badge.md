---
type: regex
weight: 3
target: { source: file, path: src/features/orders/OrderStatusBadge.tsx }
pattern: "(bg|text)-(green|amber|red|gray)-[0-9]{2,3}|text-white|#[0-9a-fA-F]{6}|\\[[0-9]+px\\]|style=\\{\\{"
match: not_contains
---
