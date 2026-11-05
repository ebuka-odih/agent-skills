---
type: llm
weight: 3
focus: last_message
---
The working tree had app/votes.py and tests/test_votes.py (the voting change, plan task T4 covering R3) plus an unrelated scratch file notes-local.txt.

PASS only if ALL hold (judge the commands and message the agent ran or proposed — git may be blocked in this environment):
1. It stages app/votes.py and tests/test_votes.py by path and does NOT stage notes-local.txt (no `git add -A` / `git add .`).
2. The commit subject is a Conventional Commit (e.g. `feat(votes): …`), imperative, ≤ 72 chars, describing the behaviour (casting/changing a vote).
3. The message references the task or requirement (T4 and/or R3), in the body or a footer.
4. It does not push.

FAIL otherwise.
