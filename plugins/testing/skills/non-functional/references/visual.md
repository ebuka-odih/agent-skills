# Visual regression (Playwright)

```ts
test('Button variants', async ({ page }) => {
  await page.goto('/storybook/iframe.html?id=ui-button--all');   // or a test-only component gallery route
  await expect(page).toHaveScreenshot('button-variants.png', { maxDiffPixelRatio: 0.01 });
});
```
- First run creates baselines; update intentionally with `npx playwright test --update-snapshots` and review the diff in the PR.
- Generate baselines in CI's container (fonts/OS differ on laptops).
- Mask dynamic regions: `mask: [page.getByTestId('timestamp')]`; freeze time and animations (`animations: 'disabled'`).
- Use for shared components and static marketing pages; avoid data-heavy dashboards (flaky).
