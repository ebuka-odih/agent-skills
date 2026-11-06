# Indexation thresholds

Set per page type in SEO.md; keep the numbers in config so the page, sitemap and robots meta all read the same value.

| Page type | Index when (example defaults) | Otherwise |
|---|---|---|
| City × category | ≥ 5 active items **and** a computed intro | noindex,follow · not in sitemap · still linked from item pages |
| City hub | ≥ 3 indexable categories | noindex,follow |
| Item page | verified name + address/location + at least one of: hours, photo, description | noindex until enriched |
| Area × category | ≥ 8 items (smaller areas merge into the city page) | redirect to city × category |
| Search/filter results | never | noindex,follow |

## Implementation pattern
```
indexable = items >= MIN_ITEMS[pageType] and has_unique_intro
robots    = "index,follow" if indexable else "noindex,follow"
sitemap   = pages where indexable
```
- One function decides `indexable`; templates, sitemap generator and tests all call it.
- Log promotions/demotions (page became indexable / dropped below) to spot data problems.
- Test: a page just under the threshold renders `noindex` and is absent from the sitemap; just over → `index` and present.
