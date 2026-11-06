#!/usr/bin/env bash
set -euo pipefail
mkdir -p gsc docs/seo
cat > gsc/Queries.csv <<'C'
Top queries,Clicks,Impressions,CTR,Position
pharmacy in wuse abuja,14,2400,0.58%,7.8
24 hour pharmacy abuja,3,1900,0.16%,12.4
hospitals in ikeja,40,1500,2.67%,4.2
best restaurants in lekki,2,3100,0.06%,18.9
brandname,90,160,56.3%,1.0
how to register a business in nigeria,0,800,0%,41
C
cat > gsc/Pages.csv <<'C'
Top pages,Clicks,Impressions,CTR,Position
https://www.example.city/ng/fct/abuja/wuse/pharmacies,10,2000,0.5%,8.1
https://www.example.city/place/medplus-wuse,4,1300,0.31%,9.5
https://www.example.city/ng/lagos/ikeja/hospitals,40,1500,2.67%,4.2
https://www.example.city/ng/lagos/lekki/restaurants,2,3100,0.06%,18.9
C
cat > ROUTES.md <<'R'
# Public routes
- /ng/<state>/<city>/<area>/<category> — category listing for an area (e.g. pharmacies in Wuse), server-rendered
- /place/<slug> — one place page (name, address, hours)
- /ng/<state>/<city> — city hub
Filters (open now, 24 hours) are query parameters on the listing: ?open=24h (noindex today).
R
