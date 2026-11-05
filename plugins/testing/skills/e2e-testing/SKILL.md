---
name: e2e-testing
description: Test a few critical user journeys end to end in a real browser with Playwright — pick journeys from SPEC.md, seed data through the API or factories, select elements by role, avoid sleeps, keep the smoke suite under five minutes, and quarantine flaky tests. Use for sign-up, login, checkout/payment, booking and other must-have journeys, when the user says "E2E", "end-to-end test", "Playwright", "browser test", "does the whole flow work"; or when test-strategy routes a journey change.
---

# End-to-end testing

E2E tests are expensive and flaky by nature. Keep few, make each one count.

## Steps
1. **Pick journeys** — from SPEC.md `J…` lines marked must, plus anything touching money or sign-in. Aim for 3–10 in total for the product, not per feature.
2. **Seed state fast** — create users/data through API calls, factories or a seed endpoint available only in test envs; log in via storage state, not the UI, except in the login test itself.
3. **Write the test** — [references/playwright.md](references/playwright.md): role/label selectors, web-first assertions (`await expect(...)`), no `waitForTimeout`.
4. **Assert the outcome a user sees** (confirmation, updated list) and one backend effect if it matters (booking exists).
5. **Run** locally headed once, then headless; in PR CI run the smoke subset (tag `@smoke`).
6. **Flake policy** — a test failing intermittently gets `test.fixme()` with an issue ID the same day; fix root cause (waiting, data collisions), never add sleeps.

## Laravel alternative
Laravel Dusk works for Blade apps; Playwright is the default for SPA/Inertia/React and for cross-browser.

## Hard rules
- Edge cases belong in feature tests, not E2E.
- Each test is independent: its own data, no order dependence, parallel-safe.
- Never run E2E against production with real payments or real users' accounts.
