---
name: non-functional
description: Test qualities that functional tests miss — load and performance (k6 with SPEC NFR thresholds against staging), accessibility (axe-core in component and Playwright tests, keyboard checks), and visual regression (Playwright screenshots for design-system components). Use when SPEC.md has latency/throughput/accessibility requirements, when a hot path or heavy query changes, when UI components change, when the user says "load test", "performance test", "is it fast enough", "accessibility", "a11y", "WCAG", "visual regression", "screenshot test"; or when test-strategy routes one of these.
---

# Non-functional testing

| Quality | Tool | Run where | Guide |
|---|---|---|---|
| Load / performance | k6 | staging (never production without sign-off) | [references/load.md](references/load.md) |
| Accessibility | axe-core (`@axe-core/playwright`, `vitest-axe`/`jest-axe`) + keyboard pass | component tests + touched pages | [references/accessibility.md](references/accessibility.md) |
| Visual regression | Playwright `toHaveScreenshot()` | design-system components, key static pages | [references/visual.md](references/visual.md) |

## Steps
1. **Find the target** — SPEC NFRs (`NFR… p95 < 300 ms at 50 rps`, `WCAG 2.2 AA`). No target → ask, or propose one and mark it `(assumed)`.
2. **Pick the scenario** — the journey or endpoint that the NFR covers, with realistic data volume.
3. **Write it with thresholds** so the run passes/fails on its own (k6 `thresholds`, zero serious axe violations, screenshot diff ratio).
4. **Run in the right place** (test-strategy budget): load nightly/pre-release on staging; a11y on every PR for touched UI; visual on PRs touching shared components.
5. **Record results** in the PR evidence and, for load, a dated row in SECURITY/ops docs or AI.md if it's an AI endpoint.

## Hard rules
- Load tests never hit production or third-party APIs (stub payment/email/AI providers on staging).
- Automated a11y checks catch ~30–50% of issues — add a keyboard-only pass for new flows.
- Visual baselines are generated in CI's environment (same OS/fonts), not on a laptop.
