# Fail correctly — status codes at each layer

| Situation | Must return | Never |
|---|---|---|
| Backend down / timing out (proxy can't reach it) | **503** + `Retry-After: 120` + a small static "back soon" page | 200 with the SPA shell or an empty page |
| Planned maintenance | 503 + `Retry-After` (Laravel `php artisan down --retry=60 --refresh=15`; FastAPI middleware flag) | 302 to a maintenance page that returns 200 |
| Dependency of one feature down (search, payments, AI) | 200 for the page, the feature degraded with a visible message, or 503 for that API route | a 500 on every page |
| Unknown URL (SPA fallback) | 404 (server knows its routes, or prerender a 404.html and serve it with `=404`) | 200 app shell for every path ("soft 404") |
| Removed content | 410 or 301 to the closest page | 200 "not found" text |
| Overload / rate limit | 429 + `Retry-After` (clients) or 503 (crawler) | silent timeouts |

## nginx
```nginx
location @app { proxy_pass http://backend; proxy_intercept_errors on; error_page 502 503 504 = @down; }
location @down { add_header Retry-After 120 always; return 503; }          # or: root /srv/maint; try_files /503.html =503;
error_page 503 /503.html; location = /503.html { root /usr/share/nginx/html; internal; }
```
- `error_page 500 502 503 504 = @spa` with an `@spa` that serves `index.html` **returns 200** — that's the masking bug.
- Keep "not mine" signals (e.g. a 421 from an SEO renderer meaning "serve the app") separate from real errors.

## Caddy
`handle_errors { @5xx expression {err.status_code} >= 500; respond @5xx "Back soon" 503 { close } }` + `header Retry-After 120`.

## Cloudflare / CDN
- "Always Online"/stale content may serve old pages during an outage — fine for users, but the origin's 503 must not be cached as a normal page (respect `Cache-Control: no-store` on errors).
- A WAF challenge served to Googlebot looks like an outage to search — check Security → Bots after enabling protections.
