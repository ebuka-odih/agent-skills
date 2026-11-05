---
type: regex
weight: 2
target: { source: file, path: docs/plan/PLAN.md }
# machine-parseable task lines: - [ ] T1 · title · covers: … · depends: … · size: S|M
pattern: "^- \\[[ ~x!-]\\] T\\d+ · .+ · covers: \\S.* · depends: \\S.* · size: [SM]"
flags: m
---
