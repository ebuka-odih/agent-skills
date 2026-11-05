---
type: llm
weight: 3
focus: { source: file, path: docs/spec/SPEC.md }
---
PASS only if ALL hold:
1. Every requirement has an ID (R1, R2…), a priority (must/should/could) and an `accept:` line that a person or test could check.
2. The brief's core behaviours are requirements: listing tools, requesting to borrow for dates, owner approve/decline, return reminder the day before, owner sees who has what.
3. There is a Non-goals section with at least 2 items, and payments is a non-goal or constraint.
4. Requirements describe behaviour, not technology (no "use Postgres/React/Redis" in requirements).
5. Assumptions not in the brief are visibly marked (e.g. "(assumed)") or listed as open questions.

FAIL if any item is missing or the file is mostly template placeholders.
