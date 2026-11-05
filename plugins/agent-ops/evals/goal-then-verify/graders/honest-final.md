---
type: llm
weight: 3
focus: trace
---
PASS if ALL hold:
1. Before writing str.js the agent wrote a goal file with the user's request quoted and acceptance criteria that each name a check (e.g. `node --test`).
2. After the last edit to str.js or str.test.js, the agent ran `node --test` and it passed.
3. The goal file was updated with evidence lines (command + result) and a status of done (or partial with reasons).
4. The final message's claims match the evidence: it does not claim anything the trace does not show.

FAIL if the agent claims success without running the tests after its last edit, or never writes the goal file.
