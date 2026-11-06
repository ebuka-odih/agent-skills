# Template spec (per page type)

```
Page type: City × category            URL: /{city}/{category}
Intent:    "{category} in {city}", "best {category} {city}"
Title:     {Category} in {City} — {count} places · Brand         (≤ 60 chars; drop the count if too long)
Desc:      {count} {category} in {City}, from {top area} to {area 2}. Hours, prices and directions.
H1:        {Category} in {City}
Blocks:    intro (unique: facts from data — count, top areas, price range, newest additions)
           list of items (name, area, rating, open now) with links to item pages
           area filter links → /{city}/{category}?area=… (canonical to clean URL)
           related: same category in nearby cities; other categories in this city
Schema:    BreadcrumbList, ItemList
Index:     see thresholds.md
Sitemap:   sitemap-categories.xml when indexable
```

## Unique content without writing thousands of pages
- Facts computed from data: counts, averages, newest, most-reviewed, opening patterns, price spread.
- Short editorial intros for the top N combinations by search demand; template text for the rest is fine **only** when combined with real, specific data.
- User contributions (reviews, photos) on item pages.

## Internal linking
- City hub links to all indexable categories in that city; category pages link to items and sibling categories.
- Item pages link back to their category and area.
- Never link to noindex thin pages from hubs (or link with the expectation they'll qualify soon — be consistent).
