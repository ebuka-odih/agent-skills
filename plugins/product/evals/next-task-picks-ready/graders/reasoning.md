---
type: llm
weight: 2
---
The plan's active milestone M1 has: T3 done, T4 todo (depends on T3), T5 todo (depends on T4), T6 blocked, T7 todo with no requirement.

PASS if the final message names T4 (cast and change a vote, covering R3) as the next task, AND either explains why T5/T6 aren't next (dependency / blocked) or notes that T7 covers no requirement. It must not claim any app code was written.
FAIL if it picks T5, T6 or T7, or starts building the feature.
