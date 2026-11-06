---
name: test-strategy
description: Decide which kinds of tests a change needs, from its conditions — what code changed (pure logic, money/auth rules, endpoints, public APIs, UI, migrations, AI), what the spec demands (journeys, NFR latency targets, accessibility) and the risk if it breaks — then route to unit/feature (code-standards testing), mutation, property-based, contract, end-to-end, load, accessibility or visual tests, and say which ones are NOT worth it. Use when the user asks "what tests should this have", "how should we test this", "is this tested enough", "mutation testing", "property testing", "load test", "E2E", "test plan", or before verifying a non-trivial change.
---

# Test strategy (orchestrator)

More tests isn't the goal; the right tests are. Pick techniques from the change's conditions, and keep the suite fast.

```
testing/skills/
├── test-strategy/     ← you are here: conditions → techniques → plan
├── mutation-testing/  do the tests catch bugs? (Pest --mutate, Infection, mutmut, Stryker)
├── property-based/    invariants over many generated inputs (Hypothesis, fast-check)
├── contract-testing/  API compatibility (OpenAPI diff, Schemathesis, Pact)
├── e2e-testing/       a few critical journeys in a real browser (Playwright)
└── non-functional/    load (k6), accessibility (axe), visual regression
code-standards:testing  unit + feature/integration tests — the base layer for every change
```

Small changes (one fix or tweak, ≤ ~3 files, no schema/API/auth/money change) don't need a strategy: one regression test that fails before and passes after is the whole job.

## Steps
1. **Get the conditions** — run the planner on the change:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/test-plan.sh" [base-ref]
   ```
   It classifies changed files and reads SPEC.md for journeys and NFRs. Then check what's installed:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/test-tools.sh"`.
2. **Apply the matrix** — [references/conditions.md](references/conditions.md). Every change gets the base layer (code-standards `testing`). Add a technique only when its condition holds.
3. **Size it** — [references/budget.md](references/budget.md): where each technique runs (every commit, PR, nightly, pre-release) so CI stays fast.
4. **Write the plan** into the GOAL.md criteria (or the PR "How to review"): technique · target · tool · threshold · when it runs.
5. **Hand off** each technique to its skill. Missing tool → propose adding it; ask before installing new dev dependencies.

## Hard rules
- The base layer is non-negotiable: behaviour change → feature/unit tests; bug fix → failing regression test first.
- Every extra technique names the condition that justifies it. No condition → don't add it.
- Never run mutation, load or full E2E suites on every commit; scope them (see budget).
- Thresholds are set on *changed* code, not the whole legacy codebase.

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log build "test plan"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
