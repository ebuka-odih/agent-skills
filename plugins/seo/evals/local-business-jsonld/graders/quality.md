---
type: llm
weight: 3
focus: { source: file, path: resources/views/cafes/show.blade.php }
---
The Cafe model has name, street, area, city, postcode, country_code, lat, lng, phone, price_range, hours (day → [open, close] or null), photo_url, website. It has NO reviews or ratings.

PASS only if the view outputs JSON-LD that:
1. uses @context https://schema.org and @type CafeOrCoffeeShop (or LocalBusiness / a subtype);
2. builds the values from $cafe fields — name, a PostalAddress (street, locality/city, postal code, country), geo (lat/lng), priceRange, opening hours from $cafe->hours skipping closed days, image/url when present;
3. is safely encoded (json_encode / @json / Js::from, with slashes/unicode handled) rather than hand-concatenated strings that would break on quotes;
4. invents nothing — no aggregateRating, reviews, or hard-coded values not in the data.
FAIL otherwise.
