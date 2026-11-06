---
name: component-testing
description: Test UI components and screens in layers — stories for every state (Storybook or Ladle), interaction tests with Testing Library and user-event, visual regression on stories (Playwright screenshots or Chromatic) in light and dark themes, accessibility checks with axe, and mocking the network with MSW. Use when adding or changing a component or screen, when the user says "test this component", "Storybook", "visual regression", "UI tests", "snapshot", "did my change break the UI"; extends testing:non-functional for frontend work.
---

# Component testing

| Layer | What it proves | Tool | Guide |
|---|---|---|---|
| Stories | every state renders (default, loading, empty, error, long text, disabled, dark) | Storybook (or Ladle) | [references/stories.md](references/stories.md) |
| Interaction | behaviour: click, type, submit, keyboard | Vitest + Testing Library + user-event | [references/interaction.md](references/interaction.md) |
| Visual | nothing moved or changed colour unintentionally | Playwright `toHaveScreenshot` on stories, or Chromatic | testing:non-functional visual.md |
| Accessibility | no serious/critical axe violations; keyboard works | axe (`@storybook/addon-a11y`, `@axe-core/playwright`) | testing:non-functional accessibility.md |
| Network | components behave with real-shaped API responses | MSW handlers shared by stories and tests | interaction.md |

## Steps
1. **App component changed** → update/add stories for each state, both themes.
2. **Behaviour changed** → interaction test querying by role/label/text, not class names or test IDs (unless there's no accessible name).
3. **Run visual tests** on touched stories; review diffs in the PR; update baselines only for intended changes.
4. **Run axe** on touched stories/pages; fix serious/critical.
5. Screens → a few page-level tests with MSW; critical journeys → `testing:e2e-testing`.

## Hard rules
- No story = not done for components in `components/app`.
- Tests don't depend on Tailwind class names or DOM structure; they use what users see.
- Visual baselines are generated in CI's environment; never commit baselines from a laptop.
