---
name: search-console
description: Read Google Search Console data to track rankings and find wins — clicks, impressions, CTR and average position; striking-distance queries (positions 4–20), titles with low CTR for their position, pages losing traffic, and diagnosing sudden traffic drops (outage, noindex, robots, canonical, migration, algorithm update). Use when the user shares a Search Console screenshot or export, says "rankings", "impressions dropped", "traffic fell", "why did clicks drop", "average position", "CTR", "GSC", or asks how the site is doing in Google.
---

# Search Console — rankings, opportunities, drops

**Input:** Performance export (Search Console → Performance → Export → CSV/zip, last 3 months; contains Queries.csv, Pages.csv, Dates.csv). A screenshot is enough to start the drop diagnosis.
**Output:** a short report (wins, losses, drop diagnosis) and tasks; keyword-map updates go to `keyword-research`.

## Steps
1. **Run** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gsc-report.sh" <export.zip|dir> [--min-impressions 50]` — prints trend (last 7 days vs previous 28), drop start date, striking-distance queries, low-CTR rows, top pages.
2. **Sudden drop?** Follow [references/diagnose-drops.md](references/diagnose-drops.md) *before* touching content: shape of the drop → likely cause → where to confirm. Then find **what changed in the 1–2 days before the drop date** — the repo's deploy/change log (DEPLOYS.md, CHANGELOG, `git log --since`), hosting/CDN/DNS changes — and name it as the prime suspect.
3. **Opportunities** — [references/opportunities.md](references/opportunities.md): striking distance → strengthen the page; low CTR → rewrite title/description (`on-page`); impressions with no matching page → `keyword-research`.
4. **Check the indexing side** — Pages (indexing) report reasons, Sitemaps status, Crawl stats host status. Live check with `site-audit`.
5. **Record** — date, change made, expected effect in SEO.md § Changes log; annotate the Search Console chart. Re-check after 2–4 weeks (positions move slowly).

## Hard rules
- Average position is impression-weighted across all queries — always look per query/page before concluding.
- Data lags ~2–3 days; the last 1–2 days are partial — don't read them as a drop.
- Never "fix" a sudden sitewide drop with content rewrites; sitewide cliffs are technical (availability, indexing directives, host/DNS) until proven otherwise.
