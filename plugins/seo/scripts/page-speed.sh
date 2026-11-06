#!/usr/bin/env bash
# Core Web Vitals for one or more URLs via the PageSpeed Insights API (field = CrUX p75, lab = Lighthouse).
# Usage: page-speed.sh <url>... [--strategy mobile|desktop] [--strict] [--lighthouse]
#        page-speed.sh --from-json <psi.json>... [--strict]      (offline: saved API responses)
#   PSI_API_KEY (env) raises the quota; without it the shared anonymous quota is often used up.
#   --lighthouse: run Lighthouse locally instead (lab only, no field data; runs `npx lighthouse`, needs Chrome).
#   --strict: exit 1 if any field metric (or lab LCP/CLS/TBT when there is no field data) is poor.
# Needs: bash, curl, jq. Read-only.
set -u
strategy=mobile; strict=0; from=0; local_lh=0; inputs=()
while [ $# -gt 0 ]; do
  case "$1" in
    --strategy) strategy="$2"; shift ;;
    --strict) strict=1 ;;
    --from-json) from=1 ;;
    --lighthouse) local_lh=1 ;;
    *) inputs+=("$1") ;;
  esac; shift
done
[ ${#inputs[@]} -gt 0 ] || { echo "usage: page-speed.sh <url>... [--strategy mobile|desktop] [--strict] | --from-json <file>..."; exit 2; }
command -v jq >/dev/null || { echo "page-speed needs jq"; exit 2; }
poor=0

# rate <metric> <value> → good | needs-improvement | poor   (Core Web Vitals thresholds, p75)
rate() {
  awk -v m="$1" -v v="$2" 'BEGIN {
    if (m=="LCP")  { g=2500; p=4000 } else if (m=="INP") { g=200; p=500 } else if (m=="CLS") { g=0.1; p=0.25 }
    else if (m=="TTFB") { g=800; p=1800 } else if (m=="FCP") { g=1800; p=3000 } else if (m=="TBT") { g=200; p=600 }
    if (v <= g) print "good"; else if (v <= p) print "needs-improvement"; else print "poor" }'
}
fmt() { # metric value → human
  case "$1" in CLS) awk -v v="$2" 'BEGIN{printf "%.2f", v}' ;; INP|TBT) printf '%s ms' "$(printf '%.0f' "$2")" ;; *) awk -v v="$2" 'BEGIN{printf "%.1f s", v/1000}' ;; esac
}
line() { # label metric value field(1|0)
  [ -n "$3" ] && [ "$3" != null ] || return 0
  local r; r=$(rate "$2" "$3")
  printf '    %-5s %-9s %s\n' "$2" "$(fmt "$2" "$3")" "$r"
  [ "$r" = poor ] && [ "$4" = 1 ] && poor=1
  return 0
}

report() { # json-file
  local j="$1" url src has_field
  jq -e '.lighthouseResult or .loadingExperience' "$j" >/dev/null 2>&1 || { echo "  not a PageSpeed Insights response: $(jq -r '.error.message // "unreadable"' "$j" 2>/dev/null)"; return 1; }
  url=$(jq -r '.lighthouseResult.finalDisplayedUrl // .lighthouseResult.finalUrl // .id // "?"' "$j")
  echo "== $url ($(jq -r '.lighthouseResult.configSettings.formFactor // "?"' "$j"))"
  # field data: the URL's own CrUX record, else the origin's
  src=url; has_field=1
  if ! jq -e '.loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS' "$j" >/dev/null 2>&1; then
    if jq -e '.originLoadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS' "$j" >/dev/null 2>&1; then src=origin; else has_field=0; fi
  fi
  if [ "$has_field" = 1 ]; then
    local k=loadingExperience; [ "$src" = origin ] && k=originLoadingExperience
    echo "  field (real users, p75, $src-level):"
    line field LCP  "$(jq -r ".$k.metrics.LARGEST_CONTENTFUL_PAINT_MS.percentile // empty" "$j")" 1
    line field INP  "$(jq -r ".$k.metrics.INTERACTION_TO_NEXT_PAINT.percentile // empty" "$j")" 1
    line field CLS  "$(jq -r ".$k.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.percentile // empty | if . == \"\" then empty else ./100 end" "$j")" 1
    line field TTFB "$(jq -r ".$k.metrics.EXPERIMENTAL_TIME_TO_FIRST_BYTE.percentile // empty" "$j")" 0
  else
    echo "  field: no CrUX data (too little traffic) — judge by lab, re-check later"
  fi
  local lab=0; [ "$has_field" = 0 ] && lab=1
  echo "  lab (Lighthouse, performance score $(jq -r '((.lighthouseResult.categories.performance.score // 0) * 100 | floor)' "$j")):"
  line lab LCP "$(jq -r '.lighthouseResult.audits["largest-contentful-paint"].numericValue // empty' "$j")" "$lab"
  line lab TBT "$(jq -r '.lighthouseResult.audits["total-blocking-time"].numericValue // empty' "$j")" "$lab"
  line lab CLS "$(jq -r '.lighthouseResult.audits["cumulative-layout-shift"].numericValue // empty' "$j")" "$lab"
  line lab FCP "$(jq -r '.lighthouseResult.audits["first-contentful-paint"].numericValue // empty' "$j")" 0
  line lab TTFB "$(jq -r '.lighthouseResult.audits["server-response-time"].numericValue // empty' "$j")" 0
  echo "  top fixes (estimated savings):"
  jq -r '[.lighthouseResult.audits[]
          | select(.score != null and .score < 0.9)
          | {t: .title, s: ([.details.overallSavingsMs // 0, (.metricSavings // {} | to_entries | map(select(.key != "CLS") | .value) | max // 0)] | max)}
          | select(.s > 0)] | sort_by(-.s) | .[:5][] | "    - \(.t) — ~\(.s | floor) ms"' "$j" | grep . || echo "    none reported"
  echo
}

lighthouse_json() { # url out-file → PSI-shaped JSON {lighthouseResult: …}
  local cmd="${SEO_LIGHTHOUSE_CMD:-npx -y lighthouse@13.0.0}"
  command -v "${cmd%% *}" >/dev/null || { echo "  no ${cmd%% *}: install Node or set PSI_API_KEY"; return 1; }
  local raw preset=""; raw="$(mktemp)"; [ "$strategy" = desktop ] && preset="--preset=desktop"
  $cmd "$1" --output=json --output-path="$raw" --quiet --only-categories=performance $preset --chrome-flags="--headless=new" >/dev/null 2>&1 \
    || { echo "  local Lighthouse failed for $1"; rm -f "$raw"; return 1; }
  jq '{lighthouseResult: .}' "$raw" > "$2"; rm -f "$raw"
}

failed=0
for x in "${inputs[@]}"; do
  if [ "$from" = 1 ]; then
    report "$x"
  else
    f="$(mktemp)"
    if [ "$local_lh" = 1 ]; then lighthouse_json "$x" "$f" && report "$f"; rm -f "$f"; continue; fi
    api="https://www.googleapis.com/pagespeedonline/v5/runPagespeed?category=performance&strategy=$strategy&url=$(jq -rn --arg u "$x" '$u|@uri')"
    [ -n "${PSI_API_KEY:-}" ] && api="$api&key=$PSI_API_KEY"
    curl -sS --max-time 150 "$api" -o "$f" || { echo "== $x: request failed"; rm -f "$f"; continue; }
    if ! jq -e '.lighthouseResult' "$f" >/dev/null 2>&1; then
      echo "== $x: PageSpeed API refused: $(jq -r '.error.message // "no result"' "$f" 2>/dev/null | cut -c1-100)"
      echo "   → set PSI_API_KEY (free, Google Cloud console) for field + lab data, or re-run with --lighthouse for lab only"
      rm -f "$f"; failed=1; continue
    fi
    report "$f"; rm -f "$f"
  fi
done
[ "$strict" = 1 ] && [ "$poor" = 1 ] && exit 1
[ "$failed" = 1 ] && exit 3
exit 0
