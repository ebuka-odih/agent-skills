---
type: regex
target: { source: file, path: docs/spec/SPEC.md }
# at least R1..R5 with a MoSCoW priority
pattern: "\\*\\*R1\\*\\* \\((must|should|could)\\)[\\s\\S]*\\*\\*R5\\*\\* \\((must|should|could)\\)"
---
