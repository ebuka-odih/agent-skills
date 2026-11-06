---
name: keyword-research
description: Find the searches a site can win and map each one to exactly one page — collect candidate queries (Search Console, autocomplete, People Also Ask, competitors, the site's own data), classify search intent, score by demand × winnability × business value, spot keyword cannibalization, and write a keyword map into docs/seo/SEO.md. Use when the user says "find keywords", "keyword research", "what should we rank for", "which pages to create", "search intent", "long-tail", "cannibalization", or when planning new landing pages.
---

# Keyword research

**Output:** a keyword map in `docs/seo/SEO.md` (§ Keywords): `query cluster → intent → target URL → status (ranking / striking distance / gap)`.

## Steps
1. **Start from what Google already shows you** — run `search-console` (`gsc-report.sh`): queries with impressions are proven demand; positions 4–20 are the fastest wins.
2. **Expand** — [references/intent-and-mapping.md](references/intent-and-mapping.md) § Sources: autocomplete, People Also Ask, related searches, competitors' titles, and *your own data* (every category × city with real items is a candidate query).
3. **Classify intent** per query (informational · navigational · commercial · transactional · local). The page type must match the intent Google rewards — check what ranks today.
4. **Cluster** queries that one page can satisfy (same intent, same results) and pick **one target URL per cluster**.
5. **Score** each cluster: demand (impressions or volume) × winnability (current position, competitor strength) × value (does it lead to the product's core action). Work top-down.
6. **Check cannibalization** — two URLs ranking for one cluster → merge, canonicalise or differentiate.
7. **Write the map** in SEO.md; new clusters with no page become tasks (programmatic pages → `programmatic-seo`, titles/h1 → `on-page`).

## Hard rules
- One primary cluster per URL; one URL per cluster.
- Don't create a page for a query you can't answer better than what ranks now (thin pages hurt the site).
- Put the primary phrase in the title, h1 and URL naturally — never stuff it.
- Volume numbers from third-party tools are estimates; Search Console impressions are the ground truth for queries you already appear for.
