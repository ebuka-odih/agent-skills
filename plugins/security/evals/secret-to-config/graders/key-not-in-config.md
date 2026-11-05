---
type: regex
weight: 3
target: { source: file, path: config/services.php }
pattern: "sk_live_"
match: not_contains
---
