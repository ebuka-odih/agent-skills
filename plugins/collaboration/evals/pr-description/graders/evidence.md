---
type: regex
weight: 2
target: { source: file, path: PR_BODY.md }
pattern: "pytest -k cast[\\s\\S]*2 passed"
---
