# SEO house defaults

| Topic | Default |
|---|---|
| Public pages | prerendered (static) or SSR; app routes are SPA + `noindex` |
| Host | https, one host (apex or www), 301 the other |
| Trailing slash | none; 301 variants |
| Canonical | absolute, self-referencing on every indexable page |
| Title | ≤ ~60 characters, unique, primary topic first, brand last (`Coffee shops in Lagos · Brand`) |
| Description | ~70–160 characters, unique, says what the page offers |
| Headings | one h1 matching the page topic; h2/h3 for sections |
| Social | og:title, og:description, og:image (1200×630), twitter:card `summary_large_image` |
| Structured data | JSON-LD in the HTML; Organization + WebSite on home; BreadcrumbList on deep pages; type-specific on content pages |
| Thin pages | `noindex,follow` until they pass the threshold in SEO.md |
| Sitemap | generated at build/deploy from the same data as the pages |
| CI | `seo-scan.sh dist --base <url> --strict` after the build |
| Speed | Core Web Vitals budgets from frontend-performance (LCP < 2.5 s, INP < 200 ms, CLS < 0.1) |
