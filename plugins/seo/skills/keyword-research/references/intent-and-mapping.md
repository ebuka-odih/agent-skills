# Intent, sources and mapping

## Intent → page type
| Intent | Query looks like | Page that wins |
|---|---|---|
| Local | "pharmacy in Wuse", "cafes near me", "open now" | place listing for that area + map, place pages with hours/address |
| Commercial | "best X in City", "X vs Y", "top 10" | curated list with criteria, comparisons |
| Transactional | "book", "buy", "price", "hire" | product/service page with the action above the fold |
| Informational | "how to", "what is", "is X safe" | guide/article, answers first |
| Navigational | brand or site name | home / brand page — make sure it ranks #1 |

Check what currently ranks: if the top 10 are lists, a single place page won't rank for that query.

## Sources (cheapest first)
| Source | How |
|---|---|
| Search Console | Queries report; striking distance (pos 4–20) and low-CTR rows from `gsc-report.sh` |
| Own data | category × area combinations with ≥ threshold items; attribute filters people search ("24 hours", "with parking") |
| Google autocomplete | type the seed + a–z; note modifiers (near me, best, cheap, open now, 24 hours) |
| People Also Ask / related searches | questions → FAQ-style sections on existing pages (not separate thin pages) |
| Competitors | their titles/URL patterns for the same city × category; gaps where they have pages and you don't |
| Paid tools (optional) | Ahrefs / Semrush / Keyword Planner for volume estimates and difficulty |

## Scoring (rough, consistent)
`priority = demand (1–5) × winnability (1–5) × value (1–3)`
- demand: impressions/month bands (≥10k=5, ≥1k=4, ≥200=3, ≥50=2, else 1) or tool volume
- winnability: current pos 4–10=5, 11–20=4, 21–50=3, not ranking but weak competitors=2, strong competitors=1
- value: leads to core action=3, supports it=2, awareness only=1

## Keyword map row (SEO.md)
`| cluster | intent | target URL | primary phrase | pos now | impressions | action |`

## Cannibalization signs
- two URLs alternate for one query over time (Search Console → query → Pages tab)
- category page and place page both titled "X in Area"
Fix: one target; the other links to it with the phrase as anchor, or is merged + 301, or retitled for a different cluster.
