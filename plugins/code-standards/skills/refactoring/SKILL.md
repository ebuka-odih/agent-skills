---
name: refactoring
description: Change code structure without changing behaviour — confirm tests cover the behaviour first (add characterization tests if not), make small mechanical steps with tests green after each, keep refactors separate from feature changes, and know when to stop. Use when the user says "refactor", "clean this up", "this file is too big", "split this", "remove duplication", "modernise this", when a function/file breaks the size limits, or before adding a feature to tangled code.
---

# Refactoring

## Steps
1. **State the goal in one line** — what gets better ("`search_v2.py` split into intent, ranking, enrichment modules") and what must not change (public API, outputs, DB).
2. **Pin behaviour** — run the existing tests. Thin coverage → write characterization tests first: call the code with real-ish inputs, snapshot current outputs, assert them. These protect you even if current behaviour is odd.
3. **Plan small steps** from [references/moves.md](references/moves.md). Each step compiles and passes tests on its own.
4. **Do one step → run tests → commit** (`refactor(scope): …`). Never batch many moves before running tests.
5. **Stop** when the stated goal is met. New ideas go to follow-ups.
6. **Separate PR** from feature work. If a feature needs a refactor, the refactor merges first.

## When not to refactor
- No tests and no time to write characterization tests → leave it; note the risk.
- Code scheduled for deletion (e.g. a legacy path with a removal date).
- During an incident.

## Hard rules
- Behaviour, outputs, public signatures and DB schema stay identical unless the goal says otherwise.
- Tests change only when they test structure that legitimately moved (imports, file paths) — never their assertions.
- A refactor PR that also changes behaviour is a feature PR; split it.
