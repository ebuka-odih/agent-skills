---
name: testing
description: Write tests that prove behaviour and catch regressions — choose the level (unit, feature/integration, contract, end-to-end), test from acceptance criteria and spec accept lines, cover failure and edge cases, use factories/fixtures, fake external services and AI models (no network in tests), and keep tests fast and deterministic. Use when adding or changing behaviour, fixing a bug (reproduce it first), when the user says "write tests", "add test coverage", "test this", "why is this test flaky", or when writing-code reaches step 4.
---

# Testing

## 1. Decide what to test
- Every acceptance criterion in GOAL.md / every `accept:` line of the covered requirement → at least one test.
- Bug fix → a test that fails before the fix, named after the bug.
- Each failure path from `error-handling` step 1 → a test.

## 2. Pick the level — [references/levels.md](references/levels.md)
Default: **feature/integration tests at the module boundary** (HTTP endpoint or service with a real test DB). Unit tests for pure logic with many cases. E2E only for critical journeys.

## 3. Write it
- Arrange → Act → Assert; one behaviour per test; name says the behaviour (`refunds in full when cancelled 2 h before class`).
- Build data with factories/fixtures; only set fields the test cares about.
- Fake the outside world: HTTP (`Http::fake`, `respx`, MSW), queues, mail, clock, AI (`Agent::fake()`, Pydantic AI `TestModel`). **No real network.**
- Assert outcomes users/callers see (response, DB state, event dispatched), not private internals.

## 4. Run and check it can fail
Run the new test, then briefly break the code (or reason it through) to confirm the test would catch it. Then run the module's suite.

Stack specifics: [references/stacks.md](references/stacks.md).

## Hard rules
- No sleeps or real time in tests — freeze/inject the clock.
- No order dependence; each test sets up its own data.
- Flaky test → fix or quarantine with an issue ID today; never "re-run until green".
- Never delete, skip or loosen an assertion to make a change pass without saying so in the PR.
