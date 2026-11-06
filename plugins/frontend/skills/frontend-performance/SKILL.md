---
name: frontend-performance
description: Keep dashboards fast — Core Web Vitals budgets (LCP, INP, CLS), JavaScript bundle budgets per route with a CI check, code-splitting heavy routes and libraries (charts, editors), data loading without waterfalls (TanStack Query prefetching, parallel queries), large-list virtualisation, image and font loading, and avoiding re-render storms. Use when the user says "the dashboard is slow", "bundle size", "Lighthouse", "Web Vitals", "page takes long to load", "table lags", or before launch.
---

# Frontend performance

## Budgets (house defaults; record in UI.md)
| Metric | Budget | Measure with |
|---|---|---|
| LCP | < 2.5 s (p75) | Lighthouse CI, real-user `web-vitals` |
| INP | < 200 ms | `web-vitals`, DevTools performance |
| CLS | < 0.1 | Lighthouse, skeletons sized like content |
| JS per route (gzip) | < 200 KB initial | bundle analyzer, size-limit in CI |

## Steps
1. **Measure first** — Lighthouse on the slow page (mobile profile) + bundle analyzer (`vite-bundle-visualizer` / `@next/bundle-analyzer`). Note the top 3 costs.
2. **Fix in this order** — [references/fixes.md](references/fixes.md):
   1. data waterfalls (parallel/prefetched queries)
   2. heavy imports (lazy-load charts, editors, date libs; import icons individually)
   3. big lists (paginate server-side or virtualise)
   4. re-renders (stable props, memo only where profiling shows it)
   5. images/fonts (sizes, lazy, `font-display: swap`)
3. **Gate it** — size-limit (or equivalent) in CI on the main bundles; Lighthouse CI on 2–3 key pages nightly.
4. **Re-measure** and record before → after in the PR.

## Hard rules
- No optimisation without a measurement before and after.
- Skeletons reserve the final size (no layout shift when data arrives).
- Don't ship a chart or rich-text library in the initial bundle of a page that doesn't show it above the fold.
