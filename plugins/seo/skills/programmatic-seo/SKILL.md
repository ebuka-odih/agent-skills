---
name: programmatic-seo
description: Generate many search landing pages from data safely — pick page templates from real search intent (city × category, item pages, comparisons), set data thresholds before a page is indexable, add unique content per page, keep internal linking and sitemaps in sync, and avoid thin or duplicate pages that hurt the whole site. Use when the user says "programmatic SEO", "generate pages for every city", "landing pages from our data", "SEO pages at scale", "category pages", or when designing page types fed by a database.
---

# Programmatic SEO

## Steps
1. **Intent first** — list the queries each template answers (`coffee shops in Lekki`, `best co-working in Abuja`). A template without a real query pattern doesn't get built.
2. **Template spec** per page type — [references/templates.md](references/templates.md): URL, title/description pattern, h1, content blocks, internal links, structured data.
3. **Thresholds** — [references/thresholds.md](references/thresholds.md): minimum data (items, unique text, freshness) before a page is indexable; below it → `noindex,follow` and out of the sitemap.
4. **Generate from one source** — pages, sitemap entries and internal links all come from the same query, so they never disagree.
5. **Monitor** — Search Console coverage per template (indexed vs "crawled – not indexed"), impressions/clicks per template; prune or merge templates that don't earn impressions.

## Hard rules
- Every generated page must be useful on its own: real items, unique intro or facts, working filters/links — not a swapped city name.
- Thin pages stay `noindex,follow` until they cross the threshold; promote automatically when they do.
- Don't create pages for combinations with no results; return 404 or redirect to the parent.
- Cap crawl waste: no infinite combinations from filters in paths; filters stay query params with canonical to the clean URL.
