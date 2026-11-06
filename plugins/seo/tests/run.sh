#!/usr/bin/env bash
# Tests for seo-scan.sh against generated fixture sites. Usage: bash plugins/seo/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN="$ROOT/scripts/seo-scan.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
B=https://example.com
DESC_OK="Independent cafes in Lagos with opening hours, prices and directions, updated every week by locals."

# page <file> — override with env: T D C H1 LANG_ ROBOTS OG HEAD BODY
page() {
  mkdir -p "$(dirname "$1")"
  local t="${T-Cafes in Lagos — 42 places · Brand}" d="${D-$DESC_OK}" c="${C-$B/}" h1="${H1-<h1>Cafes in Lagos</h1>}" lang="${LANG_-en}" og="${OG-1}"
  {
    printf '<!doctype html>\n<html%s>\n<head>\n' "${lang:+ lang=\"$lang\"}"
    [ -n "$t" ] && printf '<title>%s</title>\n' "$t"
    [ -n "$d" ] && printf '<meta name="description" content="%s">\n' "$d"
    [ -n "$c" ] && printf '<link rel="canonical" href="%s">\n' "$c"
    [ -n "${ROBOTS-}" ] && printf '<meta name="robots" content="%s">\n' "$ROBOTS"
    if [ "$og" = 1 ]; then
      printf '<meta property="og:title" content="%s">\n<meta property="og:description" content="%s">\n<meta property="og:image" content="%s/og.png">\n' "$t" "$d" "$B"
    fi
    printf '%s\n</head>\n<body>%s<p>hi</p></body>\n</html>\n' "${HEAD-}" "$h1"
  } > "$1"
}
# site <dir> — two clean pages, robots.txt, sitemap
site() {
  page "$1/index.html"
  T="About this cafe guide · Brand" D="Who writes this guide to independent cafes in Lagos, how places are chosen and how to suggest one." C="$B/about" page "$1/about/index.html"
  printf 'User-agent: *\nDisallow: /admin\n\nSitemap: %s/sitemap.xml\n' "$B" > "$1/robots.txt"
  printf '<?xml version="1.0"?>\n<urlset><url><loc>%s/</loc></url><url><loc>%s/about</loc></url></urlset>\n' "$B" "$B" > "$1/sitemap.xml"
}
k=0
fresh() { k=$((k+1)); S="$TMP/s$k"; site "$S"; }   # sets $S
scan() { bash "$SCAN" "$S" --base "$B" "$@" 2>&1; }
has()  { grep -qF -- "$2" <<<"$1"; }

echo "clean site"
fresh; out=$(scan)
check "no errors, no warnings"            'has "$out" "Result: 0 error(s), 0 warning(s) across 2 page(s)"'
check "--strict passes a clean site"      'bash "$SCAN" "$S" --base "$B" --strict >/dev/null'

echo "title and description"
fresh; T= page "$S/index.html"; out=$(scan)
check "missing title is an error"         'has "$out" "error index.html: missing <title>"'
fresh; T="Cafes in Lagos — every independent coffee place, bakery and brunch spot" page "$S/index.html"; out=$(scan)
check "title > 60 chars warns"            'has "$out" "warn  index.html: title is"'
fresh; T="Cafes in Lagos — every independent coffee place, bakery and brunc" page "$S/index.html"; out=$(scan)
check "title length counts characters, not bytes" 'has "$out" "title is 65 chars"'
fresh; T="$(printf 'x%.0s' $(seq 60))" page "$S/index.html"; out=$(scan)
check "title of exactly 60 is fine"       '! has "$out" "title is"'
fresh; T="Cafes" page "$S/index.html"; out=$(scan)
check "title < 15 chars warns"            'has "$out" "title is only 5 chars"'
fresh; T="$(printf 'x%.0s' $(seq 15))" page "$S/index.html"; out=$(scan)
check "title of exactly 15 is fine"       '! has "$out" "title is only"'
fresh; D= page "$S/index.html"; out=$(scan)
check "missing description warns"         'has "$out" "warn  index.html: missing meta description"'
fresh; D="$(printf 'd%.0s' $(seq 161))" page "$S/index.html"; out=$(scan)
check "description > 160 warns"           'has "$out" "meta description is 161 chars"'
fresh; D="$(printf 'd%.0s' $(seq 160))" page "$S/index.html"; out=$(scan)
check "description of 160 is fine"        '! has "$out" "meta description is"'
fresh; D="Short." page "$S/index.html"; out=$(scan)
check "description < 70 warns"            'has "$out" "meta description is only 6 chars"'
fresh; D="$(printf 'd%.0s' $(seq 70))" page "$S/index.html"; out=$(scan)
check "description of 70 is fine"         '! has "$out" "meta description is only"'

echo "canonical"
fresh; C= page "$S/index.html"; out=$(scan)
check "missing canonical is an error"     'has "$out" "error index.html: missing canonical"'
fresh; C=/ page "$S/index.html"; out=$(scan)
check "relative canonical is an error"    'has "$out" "canonical is not absolute: /"'
check "relative canonical: no host error" '! has "$out" "canonical host differs"'
fresh; C=https://staging.example.com/ page "$S/index.html"; out=$(scan)
check "other host vs --base is an error"  'has "$out" "canonical host differs from https://example.com"'
out=$(bash "$SCAN" "$S" 2>&1)
check "no host check without --base"      '! has "$out" "canonical host differs"'
out=$(bash "$SCAN" "$S" --base "$B/" 2>&1)
check "--base trailing slash is trimmed"  '! has "$out" "differs from https://example.com/:"'

echo "headings, lang, robots meta"
fresh; H1= page "$S/index.html"; out=$(scan)
check "no h1 is an error"                 'has "$out" "error index.html: no <h1>"'
fresh; H1="<h1>A</h1><h1 class=x>B</h1>" page "$S/index.html"; out=$(scan)
check "two h1 is an error"                'has "$out" "2 <h1> elements"'
fresh; H1="<h1>A</h1><h10>B</h10><header>x</header>" page "$S/index.html"; out=$(scan)
check "h10/header are not h1"             '! has "$out" "<h1> elements" && ! has "$out" "no <h1>"'
fresh; LANG_= page "$S/index.html"; out=$(scan)
check "missing html lang warns"           'has "$out" "missing <html lang>"'
fresh; ROBOTS="noindex,follow" D= C= OG=0 page "$S/search/index.html"; out=$(scan)
check "noindex is reported as info"       'has "$out" "info  search/index.html: noindex (noindex,follow)"'
check "noindex skips desc/canonical/og"   '! has "$out" "search/index.html: missing"'
fresh; ROBOTS="NoIndex" C="$B/s" page "$S/s/index.html"; out=$(scan)
check "NoIndex matched case-insensitively" 'has "$out" "info  s/index.html: noindex"'

echo "social tags"
fresh; OG=0 page "$S/index.html"; out=$(scan)
check "missing og:title warns"            'has "$out" "missing og:title"'
check "missing og:description warns"      'has "$out" "missing og:description"'
check "missing og:image warns"            'has "$out" "missing og:image"'
fresh; OG=0 HEAD='<meta property="og:title" content="x"><meta property="og:description" content="y"><meta property="og:image" content="/og.png">' page "$S/index.html"; out=$(scan)
check "relative og:image warns"           'has "$out" "og:image is not an absolute URL: /og.png"'

echo "structured data"
ld() { printf '<script type="application/ld+json">%s</script>' "$1"; }
fresh; HEAD="$(ld '{"@context":"https://schema.org","@type":"CafeOrCoffeeShop","name":"X"}')" page "$S/index.html"; out=$(scan)
check "valid JSON-LD passes"              'has "$out" "Result: 0 error(s)"'
fresh; HEAD="$(ld '{"@context":"https://schema.org","@type":"Cafe",}')" page "$S/index.html"; out=$(scan)
check "invalid JSON-LD is an error"       'has "$out" "invalid JSON-LD (does not parse)"'
fresh; HEAD="$(ld '{"@context":"https://schema.org","name":"X"}')" page "$S/index.html"; out=$(scan)
check "JSON-LD without @type"             'has "$out" "JSON-LD without @type"'
fresh; HEAD="$(ld '{"@type":"Organization","name":"X"}')" page "$S/index.html"; out=$(scan)
check "JSON-LD without @context"          'has "$out" "JSON-LD without @context"'
fresh; HEAD="$(ld '{"@context":"https://schema.org","@graph":[{"@type":"WebSite"}]}')" page "$S/index.html"; out=$(scan)
check "@graph counts as typed"            'has "$out" "Result: 0 error(s)"'
fresh; HEAD="$(ld '[{"@context":"https://schema.org","@type":"A"},{"name":"no type"}]')" page "$S/index.html"; out=$(scan)
check "array item without @type"          'has "$out" "JSON-LD without @type"'
fresh; HEAD="$(printf '<script type="application/ld+json">\n{\n  "@context": "https://schema.org",\n  "@type": "Organization"\n}\n</script>')" page "$S/index.html"; out=$(scan)
check "multi-line JSON-LD parses"         'has "$out" "Result: 0 error(s)"'

echo "hreflang"
alt() { printf '<link rel="alternate" hreflang="%s" href="%s">' "$1" "$2"; }
SET="$(alt en-NG $B/en-ng/)$(alt en-US $B/en-us/)$(alt x-default $B/)"
intl() { fresh
  HEAD="$SET" page "$S/index.html"
  HEAD="$SET" C="$B/en-ng/" T="Cafes in Lagos — Nigeria edition" D="$DESC_OK Nigeria." page "$S/en-ng/index.html"
  HEAD="${1:-$SET}" C="$B/en-us/" T="Cafes in Lagos — US edition" D="$DESC_OK United States." page "$S/en-us/index.html"
  printf '<urlset><url><loc>%s/</loc></url><url><loc>%s/about</loc></url><url><loc>%s/en-ng/</loc></url><url><loc>%s/en-us/</loc></url></urlset>' $B $B $B $B > "$S/sitemap.xml"
}
intl; out=$(scan)
check "reciprocal set passes"             'has "$out" "Result: 0 error(s), 0 warning(s)"'
intl "$(alt en-US $B/en-us/)$(alt x-default $B/)"; out=$(scan)
check "one-way hreflang is an error"      'has "$out" "hreflang not reciprocal: https://example.com/en-us/ does not link back to https://example.com/en-ng/"'
intl "$(alt en-NG $B/en-ng/)$(alt en-US $B/en-us/)"; out=$(scan)
check "missing x-default warns"           'has "$out" "en-us/index.html: hreflang set has no x-default"'
intl "$(alt en_NG $B/en-ng/)$(alt en-US $B/en-us/)$(alt x-default $B/)"; out=$(scan)
check "underscore code is an error"       'has "$out" "invalid hreflang code: en_NG"'
intl "$(alt en-NG /en-ng/)$(alt en-US $B/en-us/)$(alt x-default $B/)"; out=$(scan)
check "relative hreflang href is an error" 'has "$out" "hreflang en-NG href is not absolute: /en-ng/"'
fresh; HEAD="$(alt fr $B/fr/)$(alt x-default $B/)" page "$S/index.html"; out=$(scan)
check "target outside build: no reciprocity error" '! has "$out" "not reciprocal"'

echo "site-wide duplicates"
fresh; T="Cafes in Lagos — 42 places · Brand" C="$B/about" page "$S/about/index.html"; out=$(scan)
check "duplicate title is an error"       'has "$out" "error site: duplicate title"'
check "duplicate title names both files"  'has "$out" "about/index.html" && has "$out" ", index.html"'
check "duplicate description warns"       'has "$out" "warn  site: duplicate meta description"'
check "duplicate title counted once"      'has "$out" "Result: 1 error(s)"'
fresh; T="Cafes in Lagos — 42 places · Brand" ROBOTS=noindex C="$B/about" page "$S/about/index.html"; out=$(scan)
check "noindex duplicates are ignored"    '! has "$out" "duplicate"'

echo "robots.txt and sitemap"
fresh; printf 'User-agent: *\nDisallow: /\nSitemap: %s/sitemap.xml\n' $B > "$S/robots.txt"; out=$(scan)
check "Disallow: / for * is an error"     'has "$out" "error robots.txt: Disallow: / blocks the whole site"'
fresh; printf 'User-agent: BadBot\nDisallow: /\n\nUser-agent: *\nDisallow: /admin\nSitemap: %s/sitemap.xml\n' $B > "$S/robots.txt"; out=$(scan)
check "Disallow: / for one bot is fine"   '! has "$out" "blocks the whole site"'
fresh; printf 'User-agent: *\nDisallow: /admin\n' > "$S/robots.txt"; out=$(scan)
check "no Sitemap: line warns"            'has "$out" "warn  robots.txt: no Sitemap: line"'
fresh; rm "$S/robots.txt"; out=$(scan)
check "missing robots.txt warns"          'has "$out" "warn  site: no robots.txt"'
fresh; rm "$S/sitemap.xml"; out=$(scan)
check "missing sitemap warns"             'has "$out" "warn  site: no sitemap*.xml"'
fresh; printf '<urlset><url><loc>%s/</loc></url></urlset>' $B > "$S/sitemap.xml"; out=$(scan)
check "indexable page not in sitemap"     'has "$out" "about/index.html: indexable page not in sitemap: https://example.com/about"'
fresh; ROBOTS=noindex C="$B/about" T="About this cafe guide · Brand" page "$S/about/index.html"; out=$(scan)
check "noindex page in sitemap is error"  'has "$out" "noindex page is listed in the sitemap: https://example.com/about"'
fresh; mkdir -p "$S/maps"; mv "$S/sitemap.xml" "$S/maps/sitemap-pages.xml"; out=$(scan)
check "nested sitemap-*.xml is read"      'has "$out" "Result: 0 error(s), 0 warning(s)"'

echo "counts and exit codes"
fresh; T= H1= page "$S/index.html"; LANG_= C="$B/about" T="About this cafe guide · Brand" D="$DESC_OK About." page "$S/about/index.html"; out=$(scan)
check "exact error/warning counts"        'has "$out" "Result: 2 error(s), 2 warning(s) across 2 page(s)"'
check "--strict exits 1 on errors"        '! bash "$SCAN" "$S" --strict >/dev/null'
check "no --strict exits 0"               'bash "$SCAN" "$S" >/dev/null'
fresh; LANG_= page "$S/index.html"
check "--strict ignores warnings"         'bash "$SCAN" "$S" --strict >/dev/null'
fresh; T= page "$S/404.html"; out=$(scan)
check "404.html is skipped"               'has "$out" "across 2 page(s)" && ! has "$out" "404.html"'
check "missing dir: usage, exit 2"        'bash "$SCAN" "$TMP/nope" >/dev/null; [ $? = 2 ]'
mkdir -p "$TMP/empty"; out=$(bash "$SCAN" "$TMP/empty")
check "no pages: says so"                 'has "$out" "No HTML pages found"'

echo "messy HTML"
fresh; printf "<html lang='en'><head><title>Cafes in Lagos — minified page</title><meta content='%s' name='description'><link href='%s/' rel='canonical'><meta property='og:title' content='a'><meta property='og:description' content='b'><meta property='og:image' content='%s/o.png'></head><body><H1 class='x'>A</H1></body></html>" "$DESC_OK" $B $B > "$S/index.html"; out=$(scan)
check "single quotes, attr order, caps"   'has "$out" "Result: 0 error(s), 0 warning(s)"'

# ======================================================================= gsc-report.sh
GSC="$ROOT/scripts/gsc-report.sh"
echo "gsc-report"
G="$TMP/gsc"; mkdir -p "$G"
{ echo "Date,Clicks,Impressions,CTR,Position"
  for i in $(seq 1 40); do d=$(printf 'd%03d' "$i"); if [ "$i" -le 30 ]; then echo "$d,30,4000,0.75%,13.2"; else echo "$d,1,100,1%,15"; fi; done; } > "$G/Dates.csv"
printf '%s\n' 'Top queries,Clicks,Impressions,CTR,Position' '"pharmacy in wuse, abuja",12,"1,800",0.67%,6.4' 'brand name,40,90,44.4%,1.1' 'hospitals lagos,3,900,0.33%,2.2' 'rare query,0,10,0%,8' 'deep query,0,700,0%,35' 'pos four,20,60,33%,4' 'pos twenty,1,55,1.8%,20' 'pos 3.9,1,500,0.2%,3.9' > "$G/Queries.csv"
printf '%s\n' 'Top pages,Clicks,Impressions,CTR,Position' 'https://x.test/,50,500,10%,3' 'https://x.test/a,0,300,0%,24' 'https://x.test/b,0,20,0%,30' > "$G/Pages.csv"
out=$(bash "$GSC" "$G")
check "trend compares last 7 vs before"   'has "$out" "last 7 days avg: 1.0 clicks, 100 impressions/day"'
check "flags a halving as DROP"           'has "$out" "DROP: impressions fell by half"'
check "finds the first day of the drop"   'has "$out" "drop starts d031"'
check "striking distance includes 6.4"    'grep -A3 "Striking distance" <<<"$out" | grep -q "pharmacy in wuse, abuja"'
check "quoted query with comma parsed"    'has "$out" "pharmacy in wuse, abuja"'
check "1,800 parsed as 1800"              'grep "pharmacy" <<<"$out" | head -1 | grep -q " 1800 impr"'
check "positions 4 and 20 are included"   'grep -A8 "Striking distance" <<<"$out" | grep -q "pos four" && grep -A8 "Striking distance" <<<"$out" | grep -q "pos twenty"'
check "position 3.9 and 35 excluded"      '! sed -n "/Striking/,/Low CTR/p" <<<"$out" | grep -qE "pos 3.9|deep query"'
check "below min impressions excluded"    '! has "$out" "rare query"'
check "low CTR at position 2"             'sed -n "/Low CTR/,/Top pages/p" <<<"$out" | grep -q "hospitals lagos"'
check "good CTR not flagged"              '! sed -n "/Low CTR/,/Top pages/p" <<<"$out" | grep -qE "brand name|pos four"'
check "low CTR shows benchmark"           'has "$out" "(benchmark ~15%)"'
check "pages with impressions, 0 clicks"  'sed -n "/0 clicks/,\$p" <<<"$out" | grep -q "https://x.test/a"'
check "small zero-click page ignored"     '! sed -n "/0 clicks —/,\$p" <<<"$out" | grep -q "x.test/b"'
out=$(bash "$GSC" "$G" --min-impressions 1000)
check "--min-impressions raises the bar"  'has "$out" "pharmacy" && ! sed -n "/Low CTR/,/Top pages/p" <<<"$out" | grep -q "hospitals"'
(cd "$G" && zip -q "$TMP/gsc.zip" Dates.csv Queries.csv Pages.csv)
zout=$(bash "$GSC" "$TMP/gsc.zip")
check "reads a .zip export"               'has "$zout" "drop starts d031"'
mkdir -p "$TMP/flat"; { echo "Date,Clicks,Impressions,CTR,Position"; for i in $(seq 1 40); do printf 'd%03d,30,4000,0.75%%,13\n' "$i"; done; } > "$TMP/flat/Dates.csv"
out=$(bash "$GSC" "$TMP/flat")
check "steady traffic: no DROP"           '! has "$out" "DROP" && ! has "$out" "drop starts"'
mkdir -p "$TMP/none"
check "no CSVs: exit 2"                   'bash "$GSC" "$TMP/none" >/dev/null; [ $? = 2 ]'

# ======================================================================= page-speed.sh
PS="$ROOT/scripts/page-speed.sh"
echo "page-speed"
psi() { # file lcp inp cls(x100) ttfb level(url|origin|none) labLCP labTBT labCLS
  local field=""
  [ "$6" != none ] && field="\"metrics\":{\"LARGEST_CONTENTFUL_PAINT_MS\":{\"percentile\":$2},\"INTERACTION_TO_NEXT_PAINT\":{\"percentile\":$3},\"CUMULATIVE_LAYOUT_SHIFT_SCORE\":{\"percentile\":$4},\"EXPERIMENTAL_TIME_TO_FIRST_BYTE\":{\"percentile\":$5}}"
  local le="{}" ole="{}"; [ "$6" = url ] && le="{$field}"; [ "$6" = origin ] && ole="{$field}"
  cat > "$1" <<J
{"id":"https://x.test/","loadingExperience":$le,"originLoadingExperience":$ole,
 "lighthouseResult":{"finalDisplayedUrl":"https://x.test/","configSettings":{"formFactor":"mobile"},"categories":{"performance":{"score":0.42}},
  "audits":{"largest-contentful-paint":{"score":0.1,"numericValue":$7},"total-blocking-time":{"score":0.5,"numericValue":$8},"cumulative-layout-shift":{"score":1,"numericValue":$9},
   "first-contentful-paint":{"score":0.8,"numericValue":1500},"server-response-time":{"score":0.5,"numericValue":900},
   "render-blocking-insight":{"title":"Render-blocking requests","score":0,"metricSavings":{"LCP":1200,"FCP":900}},
   "image-delivery-insight":{"title":"Improve image delivery","score":0.5,"details":{"overallSavingsMs":2400}},
   "layout-shift-culprits":{"title":"Layout shift culprits","score":0,"metricSavings":{"CLS":0.3}},
   "passed-audit":{"title":"Already fine","score":1,"metricSavings":{"LCP":5000}}}}}
J
}
psi "$TMP/good.json" 2000 150 5 600 url 2400 100 0.02
out=$(bash "$PS" --from-json "$TMP/good.json")
check "field LCP 2.0 s good"              'has "$out" "LCP   2.0 s     good"'
check "field INP 150 ms good"             'has "$out" "INP   150 ms    good"'
check "field CLS percentile/100"          'has "$out" "CLS   0.05      good"'
check "url-level field data"              'has "$out" "p75, url-level"'
check "performance score shown"           'has "$out" "performance score 42"'
check "fixes sorted by savings"           '[ "$(grep -n "Improve image delivery" <<<"$out" | cut -d: -f1)" -lt "$(grep -n "Render-blocking" <<<"$out" | cut -d: -f1)" ]'
check "overallSavingsMs used"             'has "$out" "Improve image delivery — ~2400 ms"'
check "metricSavings max used"            'has "$out" "Render-blocking requests — ~1200 ms"'
check "passed audits and CLS-only hidden" '! has "$out" "Already fine" && ! has "$out" "Layout shift culprits"'
check "good page passes --strict"         'bash "$PS" --from-json "$TMP/good.json" --strict >/dev/null'
psi "$TMP/bad.json" 4100 501 26 1900 url 2400 100 0.02
out=$(bash "$PS" --from-json "$TMP/bad.json")
check "LCP 4.1 s poor"                    'has "$out" "LCP   4.1 s     poor"'
check "INP 501 ms poor"                   'has "$out" "INP   501 ms    poor"'
check "CLS 0.26 poor"                     'has "$out" "CLS   0.26      poor"'
check "TTFB 1.9 s poor"                   'has "$out" "TTFB  1.9 s     poor"'
check "poor field fails --strict"         '! bash "$PS" --from-json "$TMP/bad.json" --strict >/dev/null'
psi "$TMP/edge.json" 2500 200 10 800 url 4000 200 0.1
out=$(bash "$PS" --from-json "$TMP/edge.json")
check "boundaries are good (2.5s/200ms/0.1/0.8s)" '[ "$(grep -cE "(LCP|INP|CLS|TTFB) .* good" <<<"$(sed -n "/field/,/lab/p" <<<"$out")")" = 4 ]'
check "lab LCP 4.0 s needs-improvement"   'sed -n "/lab/,\$p" <<<"$out" | grep -q "LCP   4.0 s     needs-improvement"'
psi "$TMP/edge2.json" 2501 201 11 801 url 4001 601 0.26
out=$(bash "$PS" --from-json "$TMP/edge2.json")
check "just over: needs-improvement"      '[ "$(sed -n "/field/,/lab/p" <<<"$out" | grep -c needs-improvement)" = 4 ]'
check "TTFB poor never fails --strict"    'psi "$TMP/t.json" 2000 150 5 5000 url 2000 100 0.01; bash "$PS" --from-json "$TMP/t.json" --strict >/dev/null'
psi "$TMP/origin.json" 2000 150 5 600 origin 2000 100 0.01
out=$(bash "$PS" --from-json "$TMP/origin.json")
check "falls back to origin field data"   'has "$out" "p75, origin-level"'
psi "$TMP/nofield.json" 0 0 0 0 none 4500 700 0.3
out=$(bash "$PS" --from-json "$TMP/nofield.json")
check "no field data says so"             'has "$out" "no CrUX data"'
check "no field: lab poor fails --strict" '! bash "$PS" --from-json "$TMP/nofield.json" --strict >/dev/null'
check "with field: lab poor is not strict" 'psi "$TMP/lf.json" 2000 150 5 600 url 9000 900 0.5; bash "$PS" --from-json "$TMP/lf.json" --strict >/dev/null'
echo '{"error":{"message":"Quota exceeded"}}' > "$TMP/err.json"
out=$(bash "$PS" --from-json "$TMP/err.json")
printf '#!/usr/bin/env bash\nfor a in "$@"; do case "$a" in --output-path=*) cp "%s" "${a#--output-path=}" ;; esac; done\n' "$TMP/lhraw.json" > "$TMP/fake-lh"; chmod +x "$TMP/fake-lh"
jq '.lighthouseResult' "$TMP/good.json" > "$TMP/lhraw.json"
out=$(SEO_LIGHTHOUSE_CMD="$TMP/fake-lh" bash "$PS" https://x.test/ --lighthouse)
check "--lighthouse wraps a local run"    'has "$out" "performance score 42" && has "$out" "no CrUX data"'
out=$(SEO_LIGHTHOUSE_CMD="/nonexistent/lh" bash "$PS" https://x.test/ --lighthouse)
check "--lighthouse without the tool"     'has "$out" "no /nonexistent/lh"'
check "API error is reported"             'bash "$PS" --from-json "$TMP/err.json" > "$TMP/err.out"; grep -q "Quota exceeded" "$TMP/err.out"'
check "no args: usage, exit 2"            'bash "$PS" >/dev/null; [ $? = 2 ]'

# ======================================================================= seo-crawl.sh
CR="$ROOT/scripts/seo-crawl.sh"
echo "seo-crawl (local test server)"
python3 "$ROOT/tests/fixtures/server.py" "$TMP/port" & SRV=$!
for _ in $(seq 1 50); do [ -s "$TMP/port" ] && break; sleep 0.1; done
PORT=$(cat "$TMP/port"); O="http://127.0.0.1:$PORT"
out=$(SEO_CRAWL_SLOW_MS=400 bash "$CR" "$O" --no-hosts --max 20 --out "$TMP/crawl" 2>&1); rc=$?
kill "$SRV" 2>/dev/null; wait "$SRV" 2>/dev/null
check "crawl exits 0 without --strict"    '[ "$rc" = 0 ]'
check "finds the canonical origin"        'has "$out" "canonical host: $O"'
check "two User-agent: * groups"          'has "$out" "2 separate '"'"'User-agent: *'"'"' groups"'
check "missing child sitemap is high"     'has "$out" "high     $O/sitemaps/missing.xml: child sitemap returns 404"'
check "counts sitemap URLs"               'has "$out" "$O/sitemaps/pages.xml: 8 URL(s)"'
check "foreign-host sitemap URL"          'has "$out" "lists URLs on another host, e.g. https://elsewhere.test/x"'
check "404 in sitemap is high"            'has "$out" "high     $O/gone: returns 404 — listed in the sitemap"'
check "redirecting sitemap URL is high"   'has "$out" "$O/older: sitemap URL redirects (2 hop(s)) to $O/a"'
check "redirect chain is medium"          'has "$out" "medium   $O/older: redirect chain of 2 hops"'
check "X-Robots-Tag noindex is critical"  'has "$out" "critical $O/hidden: X-Robots-Tag header says noindex"'
check "slow TTFB is medium"               'grep -q "medium   $O/slow: slow first byte" <<<"$out"'
check "fast pages not slow"               '! has "$out" "$O/a: slow"'
check "client-rendered shell is high"     'has "$out" "high     $O/shell: client-rendered shell"'
check "foreign-host URL not fetched"      '! has "$out" "elsewhere.test/x: returns"'
check "content page is not a shell"       '! has "$out" "$O/a: client-rendered"'
check "saves fetched pages"               '[ -f "$TMP/crawl/index.html" ] && [ -f "$TMP/crawl/a/index.html" ] && [ ! -f "$TMP/crawl/gone/index.html" ]'
check "saves robots + merged sitemap"     '[ -f "$TMP/crawl/robots.txt" ] && grep -q "<loc>$O/a</loc>" "$TMP/crawl/sitemap.xml"'
check "runs seo-scan on fetched HTML"     'has "$out" "== On-page" && has "$out" "shell/index.html: no <h1>"'
check "summary counts"                    'has "$out" "Crawl result: 1 critical, 5 high, 2 medium, 1 low."'
python3 "$ROOT/tests/fixtures/server.py" "$TMP/port2" & SRV=$!
for _ in $(seq 1 50); do [ -s "$TMP/port2" ] && break; sleep 0.1; done
check "--strict exits 1 on high"          '! bash "$CR" "http://127.0.0.1:$(cat "$TMP/port2")" --no-hosts --max 3 >/dev/null 2>&1 --strict'
kill "$SRV" 2>/dev/null; wait "$SRV" 2>/dev/null
srv() { # mode [target] → sets SP (pid) and SURL
  local pf="$TMP/port.$RANDOM$RANDOM"
  python3 "$ROOT/tests/fixtures/server.py" "$pf" "$1" "${2:-}" & SP=$!
  for _ in $(seq 1 50); do [ -s "$pf" ] && break; sleep 0.1; done
  SURL="http://127.0.0.1:$(cat "$pf")"; PIDS="${PIDS:-} $SP"
}
stopall() { for p in ${PIDS:-}; do kill "$p" 2>/dev/null; wait "$p" 2>/dev/null; done; PIDS=""; }

srv clean; C="$SURL"
out=$(bash "$CR" "$C" --no-hosts --max 10 --strict 2>&1); rc=$?
check "clean site passes --strict"        '[ "$rc" = 0 ] && has "$out" "Crawl result: 0 critical, 0 high, 0 medium, 0 low."'
check "200 chars without h1 is not a shell" '! has "$out" "edge200: client-rendered"'
check "one robots group is not flagged"   '! has "$out" "separate '"'"'User-agent"'
check "no redirect marker on 200 rows"    '! has "$out" "↪"'
srv v200; V200="$SURL"; srv v301 "$C"; V301="$SURL"; srv v302 "$C"; V302="$SURL"; srv v301x; V301X="$SURL"
out=$(SEO_CRAWL_VARIANTS="$V200 $V301 $V302 $V301X $C" bash "$CR" "$C" --max 3 2>&1)
check "variant serving 200 is high"       'has "$out" "high     $V200/: also serves 200 — duplicate host"'
check "variant 301 to canonical is fine"  'has "$out" "  $V301/ → 301 $C/"'
check "variant 302 is medium"             'has "$out" "medium   $V302/: temporary redirect (302)"'
check "variant 301 elsewhere is a chain"  'has "$out" "medium   $V301X/: redirects to https://elsewhere.test/"'
check "canonical itself is skipped"       '! has "$out" "$C/: also serves"'
check "--no-hosts skips variants"         '! SEO_CRAWL_VARIANTS="$V200" bash "$CR" "$C" --max 3 --no-hosts 2>&1 | grep -q "also serves 200"'
srv edge; E="$SURL"
out=$(bash "$CR" "$E" --no-hosts --max 10 2>&1)
check "robots blocking JS is high"        'has "$out" "high     robots.txt: blocks CSS/JS"'
check "199 chars without h1 is a shell"   'has "$out" "$E/edge199: client-rendered shell: 199 characters"'
check "one hop: redirect, not a chain"    'has "$out" "$E/old: sitemap URL redirects (1 hop(s))" && ! has "$out" "$E/old: redirect chain"'
check "404 after redirect says so"        'has "$out" "$E/oldgone: returns 404 after 1 redirect(s)"'
check "redirected row marked ↪1"          'grep "$E/old$" <<<"$out" | grep -q "↪1"'
check "--strict fails on high"            '! bash "$CR" "$E" --no-hosts --max 10 --strict >/dev/null 2>&1'
srv many; M="$SURL"
out=$(bash "$CR" "$M" --no-hosts --max 2 2>&1)
check "reads the 50th child sitemap"      'has "$out" "$M/s/50.xml: 1 URL(s)"'
check "stops after 50 child sitemaps"     '! has "$out" "$M/s/51.xml:"'
srv down; Dn="$SURL"
out=$(bash "$CR" "$Dn" --no-hosts --max 5 2>&1)
check "home not 200 is critical"          'has "$out" "critical $Dn/: home page returns 503"'
check "empty sitemap is high"             'has "$out" "high     sitemap: no URLs found"'
stopall

check "bad URL: usage, exit 2"            'bash "$CR" example.com >/dev/null; [ $? = 2 ]'

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
