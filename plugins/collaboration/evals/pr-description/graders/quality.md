---
type: llm
weight: 3
focus: { source: file, path: PR_BODY.md }
---
Context: branch feat/T4-cast-vote implements plan task T4 "Cast and change a vote" covering requirement R3. The goal file shows C1 and C2 PASS with evidence (`pytest -k cast` → 2 passed, `pytest -k revote` → 1 passed) and C3 BLOCKED (rounds model not built yet, T5).

PASS only if ALL hold:
1. It names T4 and R3 (or quotes R3's requirement/accept line).
2. It includes the evidence for C1 and C2 as commands with results.
3. It has a "Not done" (or equivalent) section that states C3 is blocked and why — it does not claim the work is fully complete.
4. It describes what changed (cast/replace vote) in a few bullets.

FAIL otherwise.
