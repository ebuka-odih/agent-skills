# Accessibility testing

## Page level (Playwright + axe)
```ts
import AxeBuilder from '@axe-core/playwright';
test('booking page has no serious a11y violations', async ({ page }) => {
  await page.goto('/classes/1');
  const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag22aa']).analyze();
  expect(results.violations.filter(v => ['serious', 'critical'].includes(v.impact ?? ''))).toEqual([]);
});
```

## Component level (Vitest/Jest)
`vitest-axe` / `jest-axe`: `expect(await axe(container)).toHaveNoViolations()`.

## Manual pass for new flows (5 minutes)
- Tab through: every control reachable, visible focus, logical order, no traps
- Enter/Space activate buttons; Esc closes dialogs; focus returns after closing
- Screen reader names: buttons and inputs announce what they do
- Zoom to 200%: nothing overlaps or disappears
- Colour isn't the only signal (errors have text)

## Lint
`eslint-plugin-jsx-a11y` in React projects; fix rule violations before merge.
