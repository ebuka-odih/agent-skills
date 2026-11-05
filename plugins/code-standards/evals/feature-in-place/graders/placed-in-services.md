---
type: regex
weight: 2
target: trace
# a Write/Edit to a Python file under app/services/
pattern: '"file_path"\s*:\s*"[^"]*app/services/[a-z_]+\.py"'
---
