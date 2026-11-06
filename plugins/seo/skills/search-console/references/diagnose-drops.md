# Diagnosing a traffic drop

## By shape
| What you see | Most likely | Confirm in |
|---|---|---|
| Clicks **and** impressions fall to ~0 within 1–3 days, sitewide | site unreachable (5xx, DNS, TLS, firewall/bot protection blocking Googlebot), sitewide `noindex`, `Disallow: /`, or canonical/host change | Crawl stats → host status & response codes; Pages report "Server error (5xx)", "Excluded by noindex", "Blocked by robots.txt"; URL Inspection → Live test on 3 URLs; deploy/infra history for the start date |
| Impressions steady, clicks fall | lower CTR: SERP features/AI answers above you, worse titles, lost rich results | Search appearance; compare CTR per query; Enhancements reports |
| Gradual decline over weeks | competitors improved, content aging, algorithm update, slow pages | position trend per query; Google Search Status Dashboard (update dates); Core Web Vitals report |
| Drop on one section/template | template change: lost h1/title, canonical pointing elsewhere, JS-only content, internal links removed | Pages tab filtered by path; fetch rendered HTML of that template |
| Drop after URL change/migration | missing or chained redirects, old URLs 404, sitemap still lists old URLs | redirect old URLs one by one (`site-audit`); Pages report "Not found (404)" |
| One country/device only | hreflang/geo issue, mobile-only rendering bug | Countries / Devices tabs |

## After an outage
1. Confirm the site returns 200 to Googlebot (no challenge page) — `seo-crawl.sh` with the Googlebot UA, and URL Inspection → Live test.
2. Resubmit sitemaps; request indexing for the home and top 10 pages.
3. Add uptime monitoring on home + one deep page + sitemap (devops `observability`) so the next outage pages someone within minutes.
4. Expect recovery over days to a few weeks if the outage was short; long 5xx periods can drop URLs from the index and take longer.

## Causes that look like penalties but aren't
- Bot protection / WAF challenge served to Googlebot (Cloudflare "Under attack", bot fight mode)
- Staging `noindex` or `X-Robots-Tag` shipped to production
- Canonicals pointing to staging or http
- robots.txt replaced by a managed/default file
