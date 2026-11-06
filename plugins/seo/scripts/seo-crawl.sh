#!/usr/bin/env bash
# Crawl a live site like a search bot, then run seo-scan on what it fetched.
# Usage: seo-crawl.sh <https://www.example.com> [--max 60] [--out dir] [--no-hosts] [--strict]
#   Checks: host variants (http/https, www/apex), robots.txt, sitemap index + children, and for a
#   sample of sitemap URLs: final status, redirects, X-Robots-Tag, TTFB, client-rendered shells.
#   Saves pages + robots.txt + sitemap.xml under --out (default: temp) and runs seo-scan.sh on it.
#   --strict exits 1 on any critical/high finding. GET only, sequential.
# Env: SEO_CRAWL_UA (default Googlebot smartphone UA), SEO_CRAWL_SLOW_MS (default 1800),
#      SEO_CRAWL_VARIANTS (space-separated host variants to check instead of http/https × www/apex).
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
start="${1:-}"; shift || true
max=60; out=""; hosts=1; strict=0
while [ $# -gt 0 ]; do case "$1" in --max) max="$2"; shift ;; --out) out="$2"; shift ;; --no-hosts) hosts=0 ;; --strict) strict=1 ;; esac; shift; done
case "$start" in http://*|https://*) ;; *) echo "usage: seo-crawl.sh <https://host> [--max N] [--out dir] [--no-hosts] [--strict]"; exit 2 ;; esac
command -v curl >/dev/null && command -v perl >/dev/null || { echo "seo-crawl needs curl and perl"; exit 2; }
UA="${SEO_CRAWL_UA:-Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)}"
SLOW="${SEO_CRAWL_SLOW_MS:-1800}"
TMP="$(mktemp -d 2>/dev/null || mktemp -d "${PWD}/.seo-tmp.XXXXXX")"; trap 'rm -rf "$TMP"' EXIT
[ -n "$out" ] || out="$TMP/site"
mkdir -p "$out"
crit=0; high=0; med=0; low=0
finding() { # severity where message
  case "$1" in critical) crit=$((crit+1)) ;; high) high=$((high+1)) ;; medium) med=$((med+1)) ;; low) low=$((low+1)) ;; esac
  printf '%-8s %s: %s\n' "$1" "$2" "$3"
}
get() { # url out-file headers-file → prints "code num_redirects final_url ttfb_ms"
  curl -sS -L --max-redirs 10 --max-time 40 -A "$UA" -o "$2" -D "$3" -w '%{http_code} %{num_redirects} %{url_effective} %{time_starttransfer}' "$1" 2>/dev/null \
    | awk '{printf "%s %s %s %d", $1, $2, $3, $4*1000}' || echo "000 0 $1 0"
}
origin=$(printf '%s' "$start" | sed -E 's#^(https?://[^/]+).*#\1#')
host=${origin#*://}

echo "== Hosts"
read -r code _ final _ < <(get "$origin/" "$TMP/h" "$TMP/hh")
canon_origin=$(printf '%s' "$final" | sed -E 's#^(https?://[^/]+).*#\1#')
echo "  canonical host: $canon_origin (from $origin/ → $code)"
[ "$code" = 200 ] || finding critical "$origin/" "home page returns $code"
if [ "$hosts" = 1 ]; then
  bare=${host#www.}
  for v in ${SEO_CRAWL_VARIANTS:-"http://$bare" "https://$bare" "http://www.$bare" "https://www.$bare"}; do
    [ "$v" = "$canon_origin" ] && continue
    r=$(curl -sS -o /dev/null --max-time 20 -A "$UA" -w '%{http_code} %{redirect_url}' "$v/" 2>/dev/null || echo "000 ")
    c=${r%% *}; loc=${r#* }
    case "$c" in
      301|308) case "$loc" in "$canon_origin"*) echo "  $v/ → $c $loc" ;; *) finding medium "$v/" "redirects to $loc, not straight to $canon_origin (chain)" ;; esac ;;
      302|307) finding medium "$v/" "temporary redirect ($c) — use 301 to $canon_origin" ;;
      200) finding high "$v/" "also serves 200 — duplicate host; 301 it to $canon_origin" ;;
      000) echo "  $v/ → no response (fine if the host isn't used)" ;;
      *) echo "  $v/ → $c" ;;
    esac
  done
fi

echo; echo "== robots.txt"
read -r code _ _ _ < <(get "$canon_origin/robots.txt" "$out/robots.txt" "$TMP/rh")
if [ "$code" != 200 ]; then rm -f "$out/robots.txt"; finding medium "robots.txt" "returns $code"
else
  groups=$(grep -ciE '^[[:space:]]*user-agent:[[:space:]]*\*[[:space:]]*$' "$out/robots.txt")
  [ "$groups" -gt 1 ] && finding low "robots.txt" "$groups separate 'User-agent: *' groups (often a CDN-managed block + yours) — merge into one"
  grep -iE '^[[:space:]]*disallow:[[:space:]]*/[^[:space:]]*\.(css|js)' "$out/robots.txt" >/dev/null && finding high "robots.txt" "blocks CSS/JS — crawlers can't render pages"
  echo "  $(grep -ciE '^[[:space:]]*sitemap:' "$out/robots.txt") Sitemap line(s), $groups '*' group(s)"
fi

echo; echo "== Sitemaps"
maps=$(grep -iE '^[[:space:]]*sitemap:' "$out/robots.txt" 2>/dev/null | sed -E 's/^[[:space:]]*[Ss][Ii][Tt][Ee][Mm][Aa][Pp]:[[:space:]]*//' | tr -d '\r')
[ -n "$maps" ] || maps="$canon_origin/sitemap.xml"
: > "$TMP/locs"; : > "$TMP/children"
locs() { perl -0777 -ne 'print "$1\n" while /<loc>\s*([^<\s]+)\s*<\/loc>/g' "$1" | sed 's/&amp;/\&/g'; }
for m in $maps; do
  read -r code _ _ _ < <(get "$m" "$TMP/sm" "$TMP/smh")
  [ "$code" = 200 ] || { finding high "$m" "sitemap returns $code"; continue; }
  if grep -q '<sitemapindex' "$TMP/sm"; then locs "$TMP/sm" >> "$TMP/children"; else echo "$m" >> "$TMP/children"; cp "$TMP/sm" "$TMP/sm-direct"; fi
done
nchild=$(grep -c . "$TMP/children")
k=0; : > "$TMP/sample"
per=$(( (max + nchild - 1) / (nchild > 0 ? nchild : 1) )); [ "$per" -lt 1 ] && per=1
while IFS= read -r c; do
  [ -n "$c" ] || continue
  k=$((k+1)); [ "$k" -gt 50 ] && break
  read -r code _ _ _ < <(get "$c" "$TMP/c$k" "$TMP/ch$k")
  if [ "$code" != 200 ]; then finding high "$c" "child sitemap returns $code"; continue; fi
  n=$(locs "$TMP/c$k" | tee -a "$TMP/locs" | wc -l | tr -d ' ')
  echo "  $c: $n URL(s)"
  locs "$TMP/c$k" | head -"$per" >> "$TMP/sample"
done < "$TMP/children"
total=$(sort -u "$TMP/locs" | grep -c .)
echo "  total: $total URL(s) in $nchild sitemap(s)"
[ "$total" -gt 0 ] || finding high "sitemap" "no URLs found in $maps"
grep -v "^${canon_origin}" "$TMP/locs" | grep -q . && finding high "sitemap" "lists URLs on another host, e.g. $(grep -v "^${canon_origin}" "$TMP/locs" | head -1)"
{ echo '<?xml version="1.0" encoding="UTF-8"?><urlset>'; sort -u "$TMP/locs" | sed 's#.*#<url><loc>&</loc></url>#'; echo '</urlset>'; } > "$out/sitemap.xml"

{ echo "$canon_origin/"; sort -u "$TMP/sample" | grep -F "$canon_origin/" | grep -vxF "$canon_origin/"; } | head -"$((max + 1))" > "$TMP/fetch"
echo; echo "== Pages (sample of $(grep -c . "$TMP/fetch"), UA: ${UA##*compatible; })"
while IFS= read -r u; do
  path=$(printf '%s' "$u" | sed -E 's#^https?://[^/]+##; s#[?#].*##; s#/+$##')
  file="$out${path:-}/index.html"; mkdir -p "$(dirname "$file")"
  read -r code nr final ttfb < <(get "$u" "$file" "$TMP/ph")
  if [ "$code" != 200 ]; then
    rm -f "$file"; finding high "$u" "returns $code$( [ "$nr" -gt 0 ] && printf ' after %s redirect(s)' "$nr") — listed in the sitemap"
    continue
  fi
  [ "$nr" -gt 0 ] && finding high "$u" "sitemap URL redirects ($nr hop(s)) to $final — list the final URL"
  [ "$nr" -gt 1 ] && finding medium "$u" "redirect chain of $nr hops"
  xr=$(grep -i '^x-robots-tag:' "$TMP/ph" | tr -d '\r' | tail -1)
  case "$(printf '%s' "$xr" | tr 'A-Z' 'a-z')" in *noindex*) finding critical "$u" "X-Robots-Tag header says noindex ($xr)" ;; esac
  [ "$ttfb" -gt "$SLOW" ] && finding medium "$u" "slow first byte: ${ttfb} ms (> ${SLOW} ms)"
  info=$(perl -0777 -ne 'my $n = () = /<h1[\s>]/gi; s/<script.*?<\/script>//gis; s/<style.*?<\/style>//gis; s/<[^>]+>/ /g; s/\s+/ /g; s/^ | $//g; print length($_), " ", $n' "$file")
  chars=${info% *}; h1=${info#* }
  if [ "$chars" -lt 200 ] && [ "$h1" = 0 ]; then finding high "$u" "client-rendered shell: $chars characters of text and no h1 in the HTML crawlers get"; fi
  printf '  %s %s %4d ms %6d chars  %s\n' "$code" "$( [ "$nr" -gt 0 ] && echo "↪$nr" || echo '  ')" "$ttfb" "$chars" "$u"
done < "$TMP/fetch"

echo; echo "== On-page (seo-scan on the fetched HTML; saved in $out)"
bash "$here/seo-scan.sh" "$out" --base "$canon_origin" | sed 's/^/  /'

echo
echo "Crawl result: $crit critical, $high high, $med medium, $low low."
[ "$strict" = 1 ] && [ $((crit + high)) -gt 0 ] && exit 1
exit 0
