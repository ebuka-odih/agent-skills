---
name: on-page
description: Get each page's head and content right for search and sharing — unique titles and meta descriptions, self-referencing absolute canonicals, one h1 and logical headings, Open Graph and Twitter cards, robots meta, internal links with descriptive anchors, image alt text and dimensions, and HTTP status codes. Use when building or reviewing a public page or layout, when the user says "add meta tags", "fix the title", "canonical", "Open Graph", "social preview", "internal links", or when seo-scan reports page issues.
---

# On-page

## Steps
1. **Generate head tags from data, in one place** — a `seoMeta(page)` helper or layout props per page type, not hand-written per page. Fields: title, description, canonical, robots, og:*, twitter:*.
2. **Apply the rules** — [references/rules.md](references/rules.md) (lengths, uniqueness, canonical, headings, links, images).
3. **Stack wiring** — [references/stacks.md](references/stacks.md): Laravel Blade/Inertia, React prerender/SSR, Next.js.
4. **Check the built HTML** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/seo-scan.sh" <build-dir> --base <url>`; fix every `error`, review `warn`.
5. **Check social previews** — the og:image exists, is 1200×630, and the title/description read well when shared.

## Hard rules
- Titles and descriptions are unique per indexable page; templates must include the distinguishing data (`{place} in {area}, {city}`).
- Exactly one `<h1>` per page, describing the page's main topic.
- Canonical = the page's own clean absolute URL (https, preferred host, no tracking params).
- Missing items return 404/410 — not a 200 page with "not found" text.
- No keyword stuffing; write for the person reading the result.
