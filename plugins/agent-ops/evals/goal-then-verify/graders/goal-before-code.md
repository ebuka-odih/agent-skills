---
type: tool_order
weight: 2
before: { tool: Write, input_match: '"file_path"\s*:\s*"[^"]*GOAL\.md"' }
after:  { tool: Write, input_match: '"file_path"\s*:\s*"[^"]*/str\.js"' }
---
