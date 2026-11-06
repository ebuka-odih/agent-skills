# On-page rules

| Element | Rule | seo-scan checks |
|---|---|---|
| `<title>` | unique; ~30–60 characters; main topic first, brand last | missing (error) · > 60 or < 15 chars (warn) · duplicate across pages (error) |
| `meta description` | unique; ~70–160 characters; what the page offers + a reason to click | missing (warn) · out of range (warn) · duplicate (warn) |
| `link rel=canonical` | absolute, https, self-referencing on indexable pages | missing (error) · relative (error) · other host than `--base` (error) |
| `<h1>` | exactly one, matches the topic | none or more than one (error) |
| `html lang` | set to the page language (`en`, `en-NG`) | missing (warn) |
| `meta robots` | `noindex` only on pages meant to stay out | reported as info so accidental noindex is visible |
| Open Graph | og:title, og:description, og:image (absolute URL, 1200×630) + twitter:card | any missing (warn) |
| Structured data | valid JSON-LD with `@context` and `@type` | invalid JSON / missing fields (error) |

## Content and links
- Internal links use descriptive anchors ("coffee shops in Lekki"), not "click here".
- Every indexable page is reachable through normal links (not only via search or JS handlers); deep pages ≤ 3 clicks from home where possible.
- Breadcrumbs on hierarchical pages (with BreadcrumbList JSON-LD).
- Paginated lists link to next/previous pages with real `<a href>` links.

## Images
- `alt` describes the image's content (empty `alt=""` for decorative images).
- `width`/`height` set (prevents layout shift); modern formats (WebP/AVIF); lazy-load below the fold, not the LCP image.

## Status codes
200 for real pages · 301 for moved URLs · 404/410 for missing items · 5xx never cached as content.
