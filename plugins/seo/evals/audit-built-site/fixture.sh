#!/usr/bin/env bash
set -euo pipefail
mkdir -p dist/about dist/cafes/kofi-house dist/search
head() { printf '<!doctype html><html lang="en"><head><title>%s</title><meta name="description" content="%s"><link rel="canonical" href="%s"><meta property="og:title" content="%s"><meta property="og:description" content="%s"><meta property="og:image" content="https://example.com/og.png">%s</head><body>%s</body></html>\n' "$1" "$2" "$3" "$1" "$2" "$4" "$5"; }
D="Independent cafes in Lagos with opening hours, prices and directions, updated every week by people who live there."
head "Cafe Guide — Lagos" "$D" "https://example.com/" "" "<h1>Cafes in Lagos</h1>" > dist/index.html
head "Cafe Guide — Lagos" "Who writes this guide, how cafes are chosen and how to suggest a place you love in Lagos or Abuja." "/about" "" "<h1>About</h1>" > dist/about/index.html
head "Kofi House, Yaba — hours, menu and prices" "Kofi House in Yaba, Lagos: specialty coffee, pastries and quiet tables for work. Opening hours, prices and directions." "https://example.com/cafes/kofi-house" '<script type="application/ld+json">{"@context":"https://schema.org","@type":"CafeOrCoffeeShop","name":"Kofi House",}</script>' "<h1>Kofi House</h1><section><h1>Menu</h1></section>" > dist/cafes/kofi-house/index.html
printf '<!doctype html><html lang="en"><head><title>Search results</title><meta name="robots" content="noindex,follow"></head><body><h1>Search</h1></body></html>\n' > dist/search/index.html
printf 'User-agent: *\nDisallow: /\n' > dist/robots.txt
printf '<?xml version="1.0"?><urlset><url><loc>https://example.com/</loc></url><url><loc>https://example.com/about</loc></url><url><loc>https://example.com/cafes/kofi-house</loc></url><url><loc>https://example.com/search</loc></url></urlset>\n' > dist/sitemap.xml
