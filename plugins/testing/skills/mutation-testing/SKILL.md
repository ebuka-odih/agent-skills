---
name: mutation-testing
description: Check that tests actually catch bugs by mutating the code (flip conditions, change numbers, remove calls) and seeing which mutants survive — scoped to changed or business-critical files, with a mutation score (MSI) threshold in CI. Covers Pest --mutate and Infection (PHP), mutmut (Python) and Stryker (TypeScript). Use when code handles money, permissions, pricing or other critical rules, when the user says "mutation testing", "are our tests any good", "high coverage but bugs still slip", "MSI", or when test-strategy routes a critical change.
---

# Mutation testing

A surviving mutant = a bug your tests wouldn't catch. Kill it with a better assertion, or accept it with a reason.

## Steps
1. **Scope** — only the files test-strategy marked critical or the files changed in this branch. Never start with the whole codebase (slow, noisy, demoralising).
2. **Tool** — detected by `test-tools.sh`; setup and commands in [references/tools.md](references/tools.md):
   | Stack | Tool | Changed-files run |
   |---|---|---|
   | Laravel / Pest 3 | `pest --mutate` (tests declare `covers()` / `mutates()`) | `vendor/bin/pest --mutate --parallel --min=80` |
   | PHP (any) | Infection | `vendor/bin/infection --git-diff-filter=AM --git-diff-base=origin/main --min-msi=80 --threads=max` |
   | Python | mutmut | set `paths_to_mutate` to the changed modules → `mutmut run` → `mutmut results` |
   | TypeScript | StrykerJS | `npx stryker run --mutate "src/features/fees/**/*.ts" --incremental` |
3. **Read survivors** — for each surviving mutant: what changed (e.g. `>=` → `>`), which test should have failed. Usually it's a missing boundary assertion or an assertion on the wrong thing.
4. **Kill or accept** — add/strengthen a test (boundary value, exact amount, error raised). Equivalent mutants (no observable difference) → mark ignored with a comment.
5. **Gate** — CI runs on changed files with the threshold (≥ 80% critical, ≥ 60% elsewhere — see test-strategy budget). Record the score in the PR evidence.

## Hard rules
- Don't chase 100%: equivalent mutants exist. Explain each accepted survivor.
- Mutation runs need a green, deterministic suite first; flaky tests make results meaningless.
- Never "kill" a mutant by asserting implementation details — assert behaviour.
