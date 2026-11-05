---
type: regex
target: { source: file, path: docs/architecture/ARCHITECTURE.md }
# at least two Mermaid diagrams (context + container); more is fine
pattern: "```mermaid[\\s\\S]*```mermaid"
---
