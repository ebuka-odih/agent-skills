---
name: writing-code
description: How to write or change code in any project so it stays maintainable — read the project's rules first (ARCHITECTURE.md, AI.md, the PLAN task, existing patterns), place code in the right module, follow the stack's conventions (Laravel/PHP, FastAPI/Python, TypeScript/React), handle errors, write tests with the change, and verify with the project's own lint/type/test commands. Use whenever implementing a feature, fixing a bug, adding an endpoint, component, job or migration, or when the user says "build", "implement", "add", "fix", "write the code". Routes to structure-and-naming, error-handling, testing and refactoring.
---

# Writing code (orchestrator)

Code is read far more than written. The goal is the smallest change that fits the existing system and proves itself with tests.

```
code-standards/skills/
├── writing-code/         ← you are here: the loop every change follows
├── structure-and-naming/ where files go, what things are called, size limits
├── error-handling/       validate at the edge, fail loudly inside, log with context
├── testing/              what to test, at which level, fixtures, no network
└── refactoring/          change structure without changing behaviour
```

House defaults: [references/defaults.md](references/defaults.md). Stack guides: [Laravel](references/laravel.md) · [FastAPI](references/fastapi.md) · [TypeScript/React](references/typescript-react.md).

## The loop
1. **Read the rules first** (only what exists):
   - `docs/plan/PLAN.md` task + its `covers:` requirements in `docs/spec/SPEC.md` → what "done" means
   - `docs/architecture/ARCHITECTURE.md` → which module owns this, allowed dependencies
   - `docs/ai/AI.md` + feature card → before touching any model call
   - `AGENTS.md` / `CLAUDE.md` → project-specific rules that override these defaults
2. **Find the existing pattern.** Locate 1–2 similar features in the codebase and copy their shape (folders, naming, test style). Consistency beats your preference.
3. **Get the project's commands:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/project-commands.sh"
   ```
   It prints format / lint / types / test commands detected from the repo.
4. **Write the test first or alongside** — `testing` skill. A bug fix starts with a failing test that reproduces it. Non-trivial change → `test-strategy` (testing plugin) picks any extra techniques from the diff.
5. **Write the code** — the stack guide + `structure-and-naming` + `error-handling`. Smallest change that passes; no speculative abstractions.
6. **Run, in order:** format → lint → types → tests (fast suite, then the module's full tests). Fix every failure you caused; report ones you didn't.
7. **Scan for leftovers** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/leftover-scan.sh"` (debug calls, secrets, local paths in changed files). The hook also flags these as you edit.
8. **Hand off** — `verify-done` (agent-ops) for evidence, then `commits` (collaboration).

## Hard rules
- Don't change code unrelated to the task. Note it as a follow-up instead.
- No new dependency without checking an existing one doesn't do it; justify it in the PR.
- No commented-out code, no debug output, no `TODO` without a task/issue ID.
- Never weaken or delete a test to make it pass.
- Public behaviour changes → update docs/types/API contract in the same change.

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log build "task code"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
