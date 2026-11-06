---
type: regex
weight: 2
target: { source: file, path: src/features/orders/OrdersPage.tsx }
pattern: "(bg|text|border)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-[0-9]{2,3}|#[0-9a-fA-F]{6}|style=\\{\\{"
match: not_contains
---
