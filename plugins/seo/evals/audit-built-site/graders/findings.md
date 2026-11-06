---
type: llm
weight: 4
---
Planted problems in dist/:
(a) robots.txt has `Disallow: /` for all user agents — blocks the whole site (the most important);
(b) about/index.html has a relative canonical "/about";
(c) index.html and about/index.html share the title "Cafe Guide — Lagos";
(d) cafes/kofi-house has two <h1> elements;
(e) cafes/kofi-house has invalid JSON-LD (trailing comma — does not parse);
(f) the noindex search page is listed in sitemap.xml (and robots.txt has no Sitemap: line).

PASS if the answer identifies at least FIVE of (a)–(f), names (a) as critical / first to fix, and gives a concrete fix for each. FAIL otherwise.
