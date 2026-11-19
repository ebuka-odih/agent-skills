---
type: llm
weight: 3
---
The spec has R1–R6 (R6 dropped); nothing covers removing a candidate or showing a live tally (R3 is about casting one vote per member, which a live tally could arguably extend).

PASS if: the two requests became two separate plan tasks (one outcome each, not one combined task), each `covers:` an existing or newly added requirement — removing a candidate needs a new requirement (R7) with an accept line and a SPEC change-log row; both tasks sit in the active milestone M1 (or the agent explains another placement); the final message lists the queued tasks in order; and no app code was written.
FAIL if the requests were merged into one task, a task covers nothing or a non-existent requirement, task IDs were reused or renumbered, or app code was written.
