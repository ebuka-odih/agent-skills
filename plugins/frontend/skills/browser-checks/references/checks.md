# Findings → fixes

| Finding | Usual cause | Fix |
|---|---|---|
| `page scrolls sideways: 417px wide in a 375px viewport — culprits: h2, a, p` | long unbroken text (names, URLs, addresses), `white-space: nowrap`, fixed widths, flex children without `min-w-0` | `min-w-0` on flex/grid children, `break-words`/`overflow-wrap:anywhere` on user text, `max-w-full` on media; tables → `overflow-x-auto` wrapper |
| culprit "inside a clipped box" but the page still scrolls | the clipping box itself is wider than the viewport (e.g. table wrapper with a fixed min-width) | constrain the wrapper (`w-full max-w-full overflow-x-auto`) |
| axe `color-contrast` | token pair below 4.5:1 (text) / 3:1 (large) — often in dark mode only | fix the token in `ui-system`, not the component |
| axe `scrollable-region-focusable` | sideways chip/tab strips without focusable children | `tabindex="0"` + `role="region"` + `aria-label` on the strip, or make chips links/buttons |
| axe `definition-list` / `dlitem` | `<dl>` wrapping `<div>`s that aren't direct `dt/dd` groups, or `dt` outside `dl` | one `<div>` per `dt`+`dd` pair directly inside `dl`, or use a table/list |
| axe `button-name` / `link-name` | icon-only controls | `aria-label` |
| axe `image-alt` | missing `alt` | meaningful alt, or `alt=""` for decoration |
| broken image | wrong path, missing CDN object, lazy loader never fires | fix the source; add the page to the config |
| console error | hydration mismatch, failed fetch, uncaught exception | fix at source; ignore only third-party noise with a regex + reason |
| request 5xx | backend error on page load | the backend bug, not the check |
| load error / HTTP 4xx-5xx | page broken or URL changed | fix, or update the config in the same PR as the route change |
