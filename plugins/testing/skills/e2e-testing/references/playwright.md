# Playwright patterns

```ts
import { test, expect } from '@playwright/test';

test('member books and pays for a class @smoke', async ({ page, request }) => {
  const member = await (await request.post('/test/seed/member')).json();   // test-only seed endpoint
  await page.goto(`/login-as/${member.token}`);                              // or storageState fixture

  await page.goto('/classes');
  await page.getByRole('link', { name: /vinyasa flow/i }).click();
  await page.getByRole('button', { name: 'Book class' }).click();
  await page.getByLabel('Card number').fill('4242 4242 4242 4242');          // payment provider test card
  await page.getByRole('button', { name: 'Pay' }).click();

  await expect(page.getByRole('status')).toHaveText(/you're booked/i);
});
```

## Rules of thumb
| Do | Don't |
|---|---|
| `getByRole`, `getByLabel`, `getByText` | CSS/XPath tied to markup |
| `await expect(locator).toHaveText()` (auto-waits) | `page.waitForTimeout(2000)` |
| Unique data per test (random suffix) | Shared accounts between tests |
| `test.describe.configure({ mode: 'parallel' })` | Order-dependent tests |
| Traces on retry: `use: { trace: 'on-first-retry' }` | Retrying 5× to hide flakiness |

## Config essentials (`playwright.config.ts`)
`webServer` to start the app · `baseURL` · `retries: process.env.CI ? 1 : 0` · projects for chromium (+ webkit/firefox if users need them) · `grep: /@smoke/` for the PR job.
