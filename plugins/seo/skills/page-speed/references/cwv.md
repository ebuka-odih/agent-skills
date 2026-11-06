# Core Web Vitals

Assessed at the **75th percentile** of real visits (CrUX, rolling 28 days), separately for mobile and desktop.

| Metric | Good | Needs improvement | Poor | Measures |
|---|---|---|---|---|
| LCP — Largest Contentful Paint | ≤ 2.5 s | ≤ 4.0 s | > 4.0 s | main content visible |
| INP — Interaction to Next Paint | ≤ 200 ms | ≤ 500 ms | > 500 ms | responsiveness to taps/clicks |
| CLS — Cumulative Layout Shift | ≤ 0.1 | ≤ 0.25 | > 0.25 | visual stability |
| TTFB (diagnostic, not a CWV) | ≤ 0.8 s | ≤ 1.8 s | > 1.8 s | server + network |
| FCP (diagnostic) | ≤ 1.8 s | ≤ 3.0 s | > 3.0 s | first paint |

Lab proxies: TBT (Total Blocking Time) for INP; Lighthouse performance score is a lab summary, not a ranking signal.

## Symptom → usual cause → fix
| Symptom | Usual cause | Fix |
|---|---|---|
| High TTFB | uncached SSR, slow DB queries, cold starts, far origin | cache HTML at the edge for public pages, index queries, keep instances warm |
| LCP slow, TTFB fine | hero image late/large, render-blocking CSS/JS, client-rendered content | `fetchpriority="high"` + preload hero, AVIF/WebP with sizes, inline critical CSS, server-render the main content |
| LCP element is text but late | web fonts blocking | `font-display: swap`, preload the main font, fewer weights |
| INP poor / TBT high | big JS bundles, long tasks, heavy hydration, third-party scripts | split code per route, defer non-critical JS, move work off the main thread, trim third parties |
| CLS | images/ads/embeds without size, fonts swapping, banners injected above content | width/height or aspect-ratio on media, reserve space, `size-adjust` fallback fonts |
| Map/chart pages slow | map library loaded on first paint | lazy-load the map below the fold or on interaction; static preview image first |

## No field data?
Low-traffic URLs have no CrUX record; PSI falls back to origin-level data or none. Use lab data + the origin summary, and check again as traffic grows.
