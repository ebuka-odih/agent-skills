# Live audit checks

| Finding | Severity | Why it matters | Fix |
|---|---|---|---|
| Home or sitemap not 200 / timeout | critical | nothing gets crawled | availability first; uptime monitor |
| Second host also 200 (www and apex, http and https) | high | duplicate site, split signals | 301 every variant to the canonical host in one hop |
| Sitemap URL returns non-200 or redirects | high | wastes crawl, signals stale sitemap | generate sitemaps from the same routes/data as pages |
| Sitemap URL is noindex or canonicalises elsewhere | high | contradictory signals | sitemap = indexable canonical URLs only |
| `X-Robots-Tag: noindex` header on public pages | critical | silently deindexes | remove from production config |
| Redirect chain (> 1 hop) | medium | slower, signals diluted | point straight to the final URL |
| Client-rendered shell (tiny text, no h1/canonical in HTML) | high on key pages | indexing late/partial, no snippets | SSR/prerender that route |
| TTFB > 1.8 s (crawler fetch) | medium | slower crawl and LCP | cache HTML, warm instances |
| robots.txt has several `User-agent: *` groups | low | merged by Google but easy to misread; other crawlers differ | one `*` group |
| robots.txt blocks CSS/JS or `/` | critical if `/` | pages can't be rendered or crawled | allow assets; never `Disallow: /` for `*` |
| On-page errors from seo-scan | per check | see on-page rules | fix in the layout/template |
