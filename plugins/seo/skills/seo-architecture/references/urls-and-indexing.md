# URLs, canonicals and indexation

## URL design
| Rule | Example |
|---|---|
| Lowercase, hyphens, no file extensions | `/lagos/coffee-shops` not `/Lagos/Coffee_Shops.html` |
| Hierarchy mirrors how people search | `/{city}/{category}`, `/{city}/places/{slug}` |
| Stable slugs; IDs only if names collide | `/places/terra-kulture-vi` |
| One trailing-slash convention, enforced by 301 | always without, or always with |
| Filters/sort/pagination as query params, not new paths | `/lagos/restaurants?sort=rating` |

## Canonicals
- Every indexable page: `<link rel="canonical" href="https://…">` — absolute, self-referencing, https, the preferred host.
- Filtered/sorted/tracking-param variants canonicalise to the clean URL.
- Paginated lists: each page canonicalises to itself (not to page 1) and links to prev/next pages.
- One host: redirect `www`↔apex and http→https with 301.

## Indexation policy (record in SEO.md)
| Page type | Index? |
|---|---|
| Core content (place, product, article, category with enough items) | yes |
| Thin pages (empty category, < N items, no unique text) | `noindex,follow` until they qualify (see programmatic-seo) |
| Internal search results, filter combinations | `noindex,follow` |
| App/dashboard, auth, account, checkout | `noindex` (and not linked publicly) |
| Staging/preview environments | `noindex` + password or IP allow-list |

## Sitemaps
- `sitemap.xml` (or a sitemap index) listing **only indexable canonical URLs**, ≤ 50,000 URLs / 50 MB per file, `<lastmod>` when content really changed.
- Split by type for large sites (`sitemap-places.xml`, `sitemap-categories.xml`).
- Referenced from robots.txt and submitted in Search Console.

## robots.txt
```
User-agent: *
Disallow: /app/
Disallow: /api/
Sitemap: https://example.com/sitemap.xml
```
Never `Disallow: /` in production. Don't disallow pages you `noindex`, or the crawler can't see the noindex.
