---
type: llm
weight: 4
focus: { source: file, path: docs/seo/SEO.md }
---
The SPEC is a Laravel + Inertia React cafe directory: venue pages, ~160 generated city × category pages (many with only 1–3 cafes), filtered search results, Nigerian and US versions, and a logged-in owners' dashboard.

PASS only if this SEO plan covers at least FIVE of:
1. rendering: public pages server-rendered or prerendered (e.g. Inertia SSR), not a client-only SPA; dashboard can stay client-rendered;
2. URL scheme with clean, lowercase, hyphenated paths per page type (venue, city, city × category) and one canonical each;
3. an indexation threshold for city × category pages (a minimum number of cafes and/or unique content) — below it noindex,follow and out of the sitemap;
4. search/filter result pages are noindex (or canonical to the clean listing) and not in the sitemap; dashboard/login are noindex or disallowed;
5. sitemap(s) listing only indexable pages, and robots.txt pointing to them;
6. structured data per page type (e.g. LocalBusiness/CafeOrCoffeeShop on venues, BreadcrumbList/ItemList on listings) with no fake ratings;
7. international: locale subfolders (or similar) with reciprocal hreflang + x-default and localised currency;
8. a check in CI against the built pages (e.g. seo-scan) or another verification step.
FAIL otherwise.
