---
name: structured-data
description: Add schema.org structured data as JSON-LD so search engines understand pages and can show rich results — choose types per page (Organization, WebSite, BreadcrumbList, LocalBusiness, Product, Article, Event, Review snippet, ItemList, VideoObject), fill them only from real page data, and validate them. Use when the user says "structured data", "schema markup", "JSON-LD", "rich results", "stars in Google", "breadcrumbs in search", or when seo-scan reports invalid JSON-LD.
---

# Structured data

## Steps
1. **Pick types per page type** — [references/types.md](references/types.md). Use what Google currently supports for rich results; other schema.org types are fine for understanding but won't show as rich results.
2. **Build JSON-LD from the same data the page renders** — a function per page type (`placeJsonLd(place)`), not hand-written blobs. Values must be visible on the page.
3. **Embed** one `<script type="application/ld+json">` per entity (or an `@graph`) in the server-rendered/prerendered HTML.
4. **Validate** — `seo-scan.sh` checks JSON syntax, `@context` and `@type`; then Google's Rich Results Test / Schema Markup Validator on 2–3 sample URLs per type; watch Search Console enhancement reports after launch.

## Hard rules
- Never mark up content users can't see on the page (hidden reviews, prices or FAQs).
- No fake or self-written reviews/ratings; `aggregateRating` only from real user reviews shown on the page.
- Required properties present; omit optional ones you don't have rather than inventing them.
- Keep it in sync with the page: generated from the same source, tested in CI.
