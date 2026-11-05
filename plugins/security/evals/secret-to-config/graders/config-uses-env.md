---
type: regex
weight: 2
target: { source: file, path: config/services.php }
pattern: "env\\(\\s*['\"]STRIPE_[A-Z_]*['\"]"
---
