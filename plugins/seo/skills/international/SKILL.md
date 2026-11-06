---
name: international
description: Serve pages for several languages or regions without confusing search engines — choose the URL scheme (subfolders, subdomains, ccTLDs), add reciprocal hreflang annotations with x-default, keep one canonical per language version, localise titles/descriptions/structured data, currency and dates, and avoid auto-redirecting by IP. Use when the user says "multi-language", "hreflang", "i18n SEO", "different countries", "Nigeria and US versions", "localised pages", or when seo-scan reports hreflang issues.
---

# International SEO

## Steps
1. **Decide the scheme** — [references/hreflang.md](references/hreflang.md). Default: subfolders per locale (`/en-ng/`, `/en-us/`, `/fr/`) on one domain.
2. **One canonical per language version** — each locale page canonicalises to itself, never to another language.
3. **hreflang on every localised page** — a full, reciprocal set (each version lists all versions including itself) + `x-default`.
4. **Localise what matters** — title, description, h1, body, structured data (`priceCurrency`, `addressCountry`), dates and numbers via `Intl` per locale.
5. **Sitemaps** — either hreflang in the HTML head or `xhtml:link` alternates in the sitemap (one method, consistently).
6. **Verify** — `seo-scan.sh` checks hreflang reciprocity, absolute URLs and x-default across the built pages.

## Hard rules
- hreflang must be reciprocal; one-way annotations are ignored.
- Use valid codes: language (`en`), optionally region (`en-NG`) — region alone (`NG`) is invalid.
- Don't auto-redirect users or crawlers by IP or Accept-Language; suggest the locale with a banner instead.
- Don't machine-translate pages into indexable versions without review.
