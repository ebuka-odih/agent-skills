---
type: regex
weight: 3
target: { source: file, path: docs/plan/PLAN.md }
pattern: "^- \\[ \\] T8 · [^\\n]+ · covers: [A-Z0-9,]+ · depends: [^\\n]+ · size: [SM]\\n(?:[^\\n]*\\n)*?- \\[ \\] T9 · [^\\n]+ · covers: [A-Z0-9,]+ · depends: [^\\n]+ · size: [SM]"
flags: m
---
