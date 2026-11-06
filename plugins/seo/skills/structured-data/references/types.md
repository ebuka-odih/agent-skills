# Types per page

Source for rich-result support: Google Search Central search gallery (checked 2026-11-06) — lists Article, Breadcrumb, Event, Local business, Organization, Product, Review snippet, Software app, Video and others. **FAQ and HowTo rich results are no longer shown** (HowTo deprecated 2023; FAQ rich results retired 2026) — the markup is harmless but don't build it for rich results.

| Page | Types | Key properties |
|---|---|---|
| Home | `Organization`, `WebSite` | name, url, logo, sameAs (social profiles) |
| Any deep page | `BreadcrumbList` | itemListElement: position, name, item (absolute URL) |
| Place / venue | `LocalBusiness` (or subtype: `Restaurant`, `CafeOrCoffeeShop`, `Store`…) | name, address (PostalAddress), geo, telephone, openingHoursSpecification, url, image, priceRange; aggregateRating only from real reviews |
| Product | `Product` + `Offer` | name, image, description, offers (price, priceCurrency e.g. NGN, availability) |
| Article / blog | `Article` / `BlogPosting` | headline, image, datePublished, dateModified, author |
| Event | `Event` | name, startDate, location, eventStatus, offers |
| Category / list | `ItemList` (+ BreadcrumbList) | itemListElement with position + url |
| Video page | `VideoObject` | name, description, thumbnailUrl, uploadDate, contentUrl/embedUrl |
| App | `SoftwareApplication` | name, operatingSystem, applicationCategory, offers |

## Example — LocalBusiness
```json
{
  "@context": "https://schema.org",
  "@type": "CafeOrCoffeeShop",
  "name": "Example Coffee",
  "url": "https://example.com/lagos/places/example-coffee",
  "image": "https://example.com/img/example-coffee.jpg",
  "address": { "@type": "PostalAddress", "streetAddress": "12 Admiralty Way", "addressLocality": "Lekki", "addressRegion": "Lagos", "addressCountry": "NG" },
  "geo": { "@type": "GeoCoordinates", "latitude": 6.4474, "longitude": 3.4723 },
  "openingHoursSpecification": [{ "@type": "OpeningHoursSpecification", "dayOfWeek": ["Monday","Tuesday","Wednesday","Thursday","Friday"], "opens": "08:00", "closes": "20:00" }]
}
```
Omit `aggregateRating`, `telephone`, `priceRange` if the page doesn't show them. Coordinates only when verified (not area centroids presented as exact).
