---
type: llm
weight: 4
---
The PSI result: field (real users, p75) LCP 4.6 s = poor; INP 180 ms good; CLS 0.04 good; TTFB 0.6 s good. Lab: performance 38, LCP 6.9 s, TBT 380 ms. Opportunities: unused JavaScript ~3.1 s (maplibre-gl 820 KiB on first load), LCP request discovery ~1.4 s (LCP image not in initial HTML, fetchpriority), render-blocking ~0.9 s.

PASS only if the answer:
1. says the page fails Core Web Vitals because field LCP (4.6 s, p75) is poor, and that INP/CLS pass — judging by field data, not just the lab score of 38;
2. ranks fixes with the biggest savings first: deferring/lazy-loading the map library (unused JS) and making the LCP image discoverable/prioritised, then render-blocking resources;
3. notes server response/TTFB is fine (not the bottleneck);
4. mentions field data takes up to ~28 days to reflect fixes, or re-measuring.
FAIL otherwise.
