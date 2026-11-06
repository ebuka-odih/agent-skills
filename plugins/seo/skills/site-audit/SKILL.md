---
name: site-audit
description: Audit a live website the way a crawler sees it — fetch robots.txt and the sitemaps, crawl a sample of URLs per sitemap with a search-bot user agent, and report status codes, redirect chains, host/https consistency, X-Robots-Tag and meta noindex, sitemap URLs that aren't 200 or canonical, slow responses, and every on-page check from seo-scan. Use when the user says "audit my site", "SEO audit", "check the live site", "crawl", "is Google seeing my pages", "check redirects", or after a migration, outage or deploy that touched routing.
---

# Live site audit

**Output:** a findings list ordered by impact — `severity · URL(s) · evidence · fix` — and, for another agent, a handoff file with file hints when the codebase is available.

## Steps
1. **Crawl** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/seo-crawl.sh" https://www.example.com [--max 60] [--out dir]`: reads robots.txt and sitemap index, samples URLs from each child sitemap, fetches each with a Googlebot UA, records status / redirects / X-Robots-Tag / TTFB, then runs `seo-scan.sh` on the fetched HTML.
2. **Host checks** — http→https, apex↔www: exactly one 200 host; the others 301 to it in one hop. Checked by the crawler.
3. **Read the findings** with [references/checks.md](references/checks.md) (what each finding means and its severity).
4. **Speed** — one URL per template through `page-speed`.
5. **Rendering** — pages whose fetched HTML has almost no text or no h1 are client-rendered shells: crawlers may index them late or poorly → `seo-architecture` rendering.
6. **Hand off** — group by root cause (one template fix beats 500 URL fixes); map each to the code (route, layout, sitemap generator) when the repo is available.

## Hard rules
- Read-only: GET requests only, polite rate (sequential, small sample), honour robots.txt for paths you crawl.
- Report evidence (URL, status, header, snippet) for every finding — no "probably".
- Fix causes at the template/generator, not URL by URL.
