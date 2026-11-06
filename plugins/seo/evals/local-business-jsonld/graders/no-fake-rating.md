---
type: regex
weight: 3
target: { source: file, path: resources/views/cafes/show.blade.php }
pattern: "aggregateRating|ratingValue|reviewCount"
match: not_contains
---
