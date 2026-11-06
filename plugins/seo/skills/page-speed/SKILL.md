---
name: page-speed
description: Measure and improve page speed for search — Core Web Vitals (LCP, INP, CLS) from real-user field data (CrUX) and lab data (Lighthouse) via PageSpeed Insights, per page template and device, with the top fixes ranked by savings. Use when the user says "page speed", "site is slow", "Core Web Vitals", "LCP", "INP", "CLS", "PageSpeed", "Lighthouse score", "TTFB", or when Search Console's Core Web Vitals report shows poor URLs.
---

# Page speed (Core Web Vitals)

**Output:** a speed table per template (home, listing, detail) × mobile/desktop with field p75 and lab values, and the top fixes → tasks.

## Steps
1. **Pick one URL per template** (pages share code, so they share problems), mobile first.
2. **Measure** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/page-speed.sh" <url>… [--strategy mobile|desktop]` (PageSpeed Insights API; set `PSI_API_KEY` for more than a few calls). Field data (real Chrome users, 28 days) decides the ranking signal; lab data explains why.
3. **Read it** with [references/cwv.md](references/cwv.md): thresholds, which metric points to which cause.
4. **Fix the biggest saving first**, by template; implementation details → `frontend:frontend-performance`. Server/TTFB issues → hosting, caching, CDN (devops).
5. **Re-measure** lab right away; field data needs up to 28 days to reflect a fix.
6. **Guard it** — Lighthouse CI or a budget in CI for the key templates (devops `ci`).

## Hard rules
- Judge by field p75 when it exists; a lab score alone is not the ranking signal.
- Measure the deployed production URL, not localhost.
- Never trade content crawlers need (server-rendered text, links) for a faster empty shell.
