#!/usr/bin/env bash
set -euo pipefail
mkdir -p psi
cat > psi/home.json <<'J'
{"id":"https://www.example.city/","loadingExperience":{"overall_category":"SLOW","metrics":{
 "LARGEST_CONTENTFUL_PAINT_MS":{"percentile":4600,"category":"SLOW"},
 "INTERACTION_TO_NEXT_PAINT":{"percentile":180,"category":"FAST"},
 "CUMULATIVE_LAYOUT_SHIFT_SCORE":{"percentile":4,"category":"FAST"},
 "EXPERIMENTAL_TIME_TO_FIRST_BYTE":{"percentile":600,"category":"FAST"}}},
 "lighthouseResult":{"finalDisplayedUrl":"https://www.example.city/","configSettings":{"formFactor":"mobile"},
  "categories":{"performance":{"score":0.38}},
  "audits":{
   "largest-contentful-paint":{"score":0.05,"numericValue":6900},
   "total-blocking-time":{"score":0.6,"numericValue":380},
   "cumulative-layout-shift":{"score":1,"numericValue":0.02},
   "first-contentful-paint":{"score":0.5,"numericValue":2600},
   "server-response-time":{"score":1,"numericValue":180},
   "render-blocking-insight":{"title":"Render-blocking requests","score":0,"metricSavings":{"LCP":900,"FCP":900}},
   "unused-javascript":{"title":"Reduce unused JavaScript","score":0,"details":{"overallSavingsMs":3100},"description":"maplibre-gl.js 820 KiB unused on first load"},
   "lcp-discovery-insight":{"title":"LCP request discovery","score":0,"metricSavings":{"LCP":1400},"description":"LCP image is not discoverable in the initial HTML; add fetchpriority=high"},
   "font-display-insight":{"title":"Font display","score":0.5,"metricSavings":{"FCP":200}}}}}
J
