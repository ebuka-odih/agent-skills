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

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
