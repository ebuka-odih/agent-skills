#!/usr/bin/env bash
set -euo pipefail
mkdir -p audit
cat > audit/crawl.txt <<'T'
== Hosts
  canonical host: https://www.example.city (from https://www.example.city/ → 200)
high     https://example.city/: also serves 200 — duplicate host; 301 it to https://www.example.city
== robots.txt
low      robots.txt: 2 separate 'User-agent: *' groups (often a CDN-managed block + yours) — merge into one
== Sitemaps
  total: 12000 URL(s) in 6 sitemap(s)
== Pages (sample of 40)
critical https://www.example.city/guides/lagos: X-Robots-Tag header says noindex (X-Robots-Tag: noindex)
critical https://www.example.city/guides/abuja: X-Robots-Tag header says noindex (X-Robots-Tag: noindex)
high     https://www.example.city/: client-rendered shell: 38 characters of text and no h1 in the HTML crawlers get
high     https://www.example.city/old-lagos: sitemap URL redirects (1 hop(s)) to https://www.example.city/ng/lagos — list the final URL
medium   https://www.example.city/ng/rivers: slow first byte: 2300 ms (> 1800 ms)
== On-page
  error index.html: missing canonical
  error index.html: no <h1>
  warn  ng/lagos/index.html: title is 71 chars (aim ≤ 60)
Crawl result: 2 critical, 3 high, 1 medium, 1 low.
T
cat > nginx.conf <<'N'
server {
  listen 80;
  location /guides/ { add_header X-Robots-Tag "noindex" always; try_files $uri $uri/index.html =404; }
  location / { try_files $uri $uri/index.html @render; }
  location @render { proxy_pass http://backend:8000/render$request_uri; }
}
N
