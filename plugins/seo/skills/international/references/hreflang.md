# Locale schemes and hreflang

| Scheme | Example | Pros | Cons |
|---|---|---|---|
| **Subfolders** (default) | `example.com/en-ng/` | one domain's authority, simple ops | needs clean routing |
| Subdomains | `ng.example.com` | separate hosting per region | authority split, more setup |
| ccTLDs | `example.ng` | strongest country signal | separate sites to grow and maintain |
| Params | `?lang=fr` | — | avoid: weak signal, crawl issues |

## hreflang set (in every version's head)
```html
<link rel="alternate" hreflang="en-NG" href="https://example.com/en-ng/lagos/cafes">
<link rel="alternate" hreflang="en-US" href="https://example.com/en-us/austin/cafes">
<link rel="alternate" hreflang="x-default" href="https://example.com/lagos/cafes">
```
- Same set on each listed page (reciprocal), absolute URLs, each pointing at an indexable canonical URL.
- `x-default` = the page for users whose locale isn't listed (often a locale chooser or the main version).
- Pages that exist in one locale only don't get hreflang.

## Localising data
- Currency: `Intl.NumberFormat(locale, { style: "currency", currency })` — NGN for `en-NG`, USD for `en-US`.
- Dates/times: `Intl.DateTimeFormat` with the venue's time zone, not the server's.
- Structured data: `priceCurrency`, `addressCountry`, `inLanguage`.
