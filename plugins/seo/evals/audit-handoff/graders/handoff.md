---
type: llm
weight: 4
focus: { source: file, path: audit/HANDOFF.md }
---
PASS only if HANDOFF.md:
1. puts the X-Robots-Tag noindex on /guides/ first (critical) and traces it to the `add_header X-Robots-Tag "noindex"` line in nginx.conf as the single root cause for both URLs;
2. explains the homepage shell (no h1/canonical) and points at `try_files $uri $uri/index.html` serving the static index for `/` instead of the renderer, with a fix (route `/` to the renderer or prerender the home);
3. includes the duplicate host (301 apex → www) and the redirecting sitemap URL (list the final URL / fix the sitemap generator);
4. gives evidence (URL/header/line) and a concrete fix for each item, ordered by severity.
FAIL otherwise.
