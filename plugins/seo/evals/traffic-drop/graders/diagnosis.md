---
type: llm
weight: 4
---
The export shows impressions and clicks falling from ~4,000/day to ~60/day starting 2026-10-20, sitewide, the day after a deploy that moved hosting behind a CDN with bot protection (DEPLOYS.md).

PASS only if the answer:
1. identifies the sudden sitewide cliff and its start date (around 2026-10-20);
2. treats it as technical first — availability/bot protection blocking Googlebot, 5xx, noindex/robots or host change — linking it to the 2026-10-19 deploy, and does NOT recommend content rewrites as the first step;
3. gives concrete ways to confirm in Search Console (Crawl stats host status/response codes, Pages report reasons, URL Inspection live test) and/or by fetching as Googlebot;
4. gives recovery steps (fix the block, resubmit sitemap, request indexing, monitor).
FAIL otherwise.
