---
type: llm
weight: 3
focus: { source: file, path: docs/plan/PLAN.md }
---
The spec has must requirements R1–R4, should R5, and R6 which is DROPPED.

PASS only if ALL hold:
1. R1, R2, R3 and R4 are each named in the `covers:` field of at least one task.
2. R5 is either covered by a task or listed under a Deferred section with a reason.
3. R6 is not planned as work (it is dropped).
4. After an optional first "Foundations"/M0 milestone (repo, CI, data setup, deploy skeleton — allowed and expected when there is no code), the feature milestones are vertical slices that each deliver something a user can do, not layers like "all database work", "all API", "all UI".
5. Tasks have dependencies that make sense (e.g. closing a vote depends on voting).

FAIL otherwise.
