---
type: regex
weight: 2
target: { source: file, path: .github/workflows/backend.yml }
pattern: "uv sync[^\\n]*--(frozen|locked)"
---
