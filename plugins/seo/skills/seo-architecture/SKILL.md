---
name: seo-architecture
description: Entry point for technical SEO — decide how pages are rendered for crawlers (SSR, static/prerender, SPA), design URLs, set the indexation policy (what's indexable, canonical rules, noindex thresholds for thin pages), plan sitemaps and robots.txt, and record it in docs/seo/SEO.md; then audit the built site with seo-scan.sh and gate CI. Use when launching a public site or app pages, when the user says "SEO", "make this rank", "Google isn't indexing", "sitemap", "canonical", "SEO architecture", "programmatic pages", or before adding public pages. Routes to on-page, structured-data, programmatic-seo and international.
---

# SEO architecture (orchestrator)

Search engines see what your server sends and what your URLs promise. Architecture decisions (rendering, URLs, indexation) matter more than keywords — get them right once.

```
seo/skills/
├── seo-architecture/  ← you are here: rendering, URLs, indexation, sitemaps, SEO.md, audit
├── on-page/           titles, descriptions, canonicals, headings, Open Graph, internal links, images
├── structured-data/   JSON-LD per page type, validation
├── programmatic-seo/  template pages from data (city × category…), thin-content guards
└── international/     locales, hreflang, x-default, currency/date formats
```
Related: Core Web Vitals → `frontend:frontend-performance` · CI gate → `devops:ci` · which pages matter → `docs/spec/SPEC.md` (product).

**Output:** `docs/seo/SEO.md` (from [templates/SEO.md](templates/SEO.md)).

## Steps
1. **Which pages should rank?** From SPEC.md journeys and the user: list page types (home, category, place/product, article, landing, programmatic). Mark each indexable or not (dashboards, auth, search results with arbitrary params are usually not).
2. **Rendering** per page type — [references/rendering.md](references/rendering.md). Indexable pages must ship meaningful HTML (title, meta, main content, links) without running JavaScript.
3. **URLs and indexation** — [references/urls-and-indexing.md](references/urls-and-indexing.md): one canonical URL per thing, lowercase-hyphenated paths, parameter handling, noindex rules, sitemap and robots.txt.
4. **Per-page rules** → `on-page`; **rich results** → `structured-data`; **pages generated from data** → `programmatic-seo`; **multiple languages/regions** → `international`.
5. **Audit the build** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/seo-scan.sh" <build-dir> --base https://example.com` (prerendered/static HTML). Fix errors; add `--strict` as a CI step after the build (devops `ci`).
6. **Write SEO.md** and add to CLAUDE.md/AGENTS.md: `SEO: docs/seo/SEO.md — read before adding public pages or changing URLs.`

House defaults: [references/defaults.md](references/defaults.md).

## Hard rules
- A URL that changes must 301 to the new one; never break indexed URLs silently.
- Every indexable page has a self-referencing absolute canonical, a unique title and description, and one h1.
- `robots.txt` controls crawling, not indexing — use `noindex` (meta or header) to keep pages out of results, and don't also block them in robots.txt (the crawler must see the noindex).
- Don't generate pages you wouldn't show a user: thin or duplicate pages hurt the whole site.
