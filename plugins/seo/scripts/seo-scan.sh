#!/usr/bin/env bash
# Audit a built (static / prerendered) site for technical SEO problems.
# Usage: seo-scan.sh <build-dir> [--base https://example.com] [--strict]
#   --base    expected canonical origin (canonicals/og:image must start with it)
#   --strict  exit 1 when any error is found (for CI after the build)
# Needs: bash, perl, jq. Read-only.
set -u
dir="${1:-}"; shift || true
base=""; strict=0
while [ $# -gt 0 ]; do case "$1" in --base) base="${2%/}"; shift ;; --strict) strict=1 ;; esac; shift; done
[ -n "$dir" ] && [ -d "$dir" ] || { echo "usage: seo-scan.sh <build-dir> [--base https://host] [--strict]"; exit 2; }
command -v perl >/dev/null && command -v jq >/dev/null || { echo "seo-scan needs perl and jq"; exit 2; }

errors=0; warns=0
issue() { # severity file message
  case "$1" in error) errors=$((errors+1)) ;; warn) warns=$((warns+1)) ;; esac
  printf '%-5s %s: %s\n' "$1" "$2" "$3"
}

# parse < html — one pass per page; prints "key<TAB>value" lines (perl copes with minified / multi-line HTML)
parse() {
  perl -0777 -ne '
    sub attr { my ($tag, $name) = @_; return $tag =~ /\b$name\s*=\s*["\x27]([^"\x27]*)["\x27]/i ? $1 : undef }
    sub flat { my $v = shift // ""; $v =~ s/\s+/ /g; $v =~ s/^ | $//g;
      $v =~ s/&#x([0-9a-f]+);/chr(hex $1)/gie; $v =~ s/&#(\d+);/chr $1/ge;   # entities count as one character
      my %e = (amp=>"&", lt=>"<", gt=>">", quot=>"\"", apos=>"\x27", nbsp=>" "); $v =~ s/&(amp|lt|gt|quot|apos|nbsp);/$e{$1}/g; return $v }
    sub chars { my $v = shift; utf8::decode($v); return length $v }   # characters, not bytes, in any locale
    my $h = $_;
    print "title\t", flat($1), "\n" while $h =~ /<title[^>]*>(.*?)<\/title>/gis;
    print "tlen\t", chars(flat($1)), "\n" if $h =~ /<title[^>]*>(.*?)<\/title>/is;
    my $n = () = $h =~ /<h1[\s>]/gi; print "h1\t$n\n";
    print "lang\t", flat(attr(($h =~ /(<html[^>]*>)/i)[0] // "", "lang")), "\n";
    while ($h =~ /<script[^>]*application\/ld\+json[^>]*>(.*?)<\/script>/gis) { print "ld\t", flat($1), "\n" }
    while ($h =~ /(<link\b[^>]*>)/gi) { my $t = $1; my $r = lc(attr($t,"rel") // "");
      print "canonical\t", flat(attr($t,"href")), "\n" if $r eq "canonical";
      print "hreflang\t", flat(attr($t,"hreflang")), "\t", flat(attr($t,"href")), "\n" if $r eq "alternate" && defined attr($t,"hreflang") }
    while ($h =~ /(<meta\b[^>]*>)/gi) { my $t = $1; my $k = lc(attr($t,"name") // attr($t,"property") // "");
      print "$k\t", flat(attr($t,"content")), "\n" if $k =~ /^(description|robots|og:title|og:description|og:image)$/;
      print "dlen\t", chars(flat(attr($t,"content"))), "\n" if $k eq "description" }
  '
}

TMP="$(mktemp -d 2>/dev/null || mktemp -d "${PWD}/.seo-tmp.XXXXXX")"; trap 'rm -rf "$TMP"' EXIT
pages="$TMP/pages.tsv"; alts="$TMP/alts.tsv"; : > "$pages"; : > "$alts"
n=0

while IFS= read -r f; do
  rel="${f#"$dir"/}"
  case "$rel" in 404.html|*/404.html|500.html) continue ;; esac
  n=$((n+1))
  tl=0 dl="" title="" desc="" canon="" robots="" h1=0 lang="" ogt="" ogd="" ogi="" lds="" alts_page=""
  while IFS=$'\t' read -r k v; do
    case "$k" in
      title) [ -n "$title" ] || title="$v" ;;
      tlen) tl="$v" ;;
      dlen) [ -n "$dl" ] || dl="$v" ;;
      description) [ -n "$desc" ] || desc="$v" ;;
      canonical) [ -n "$canon" ] || canon="$v" ;;
      robots) [ -n "$robots" ] || robots=$(tr 'A-Z' 'a-z' <<<"$v") ;;
      h1) h1="$v" ;;
      lang) lang="$v" ;;
      og:title) ogt="$v" ;;
      og:description) ogd="$v" ;;
      og:image) [ -n "$ogi" ] || ogi="$v" ;;
      ld) lds="$lds$v"$'\n' ;;
      hreflang) alts_page="$alts_page$v"$'\n' ;;
    esac
  done < <(parse < "$f")
  noindex=0; case "$robots" in *noindex*) noindex=1 ;; esac

  # title / description
  [ -z "$title" ] && issue error "$rel" "missing <title>"
  if [ -n "$title" ]; then
    [ "$tl" -gt 60 ] && issue warn "$rel" "title is $tl chars (aim ≤ 60): $title"
    [ "$tl" -lt 15 ] && issue warn "$rel" "title is only $tl chars: $title"
  fi
  [ -z "$desc" ] && [ "$noindex" = 0 ] && issue warn "$rel" "missing meta description"
  if [ -n "$desc" ]; then
    [ "$dl" -gt 160 ] && issue warn "$rel" "meta description is $dl chars (aim 70–160)"
    [ "$dl" -lt 70 ] && issue warn "$rel" "meta description is only $dl chars (aim 70–160)"
  fi
  # canonical
  if [ -z "$canon" ]; then
    [ "$noindex" = 0 ] && issue error "$rel" "missing canonical"
  else
    grep -qE '^https?://' <<<"$canon" || issue error "$rel" "canonical is not absolute: $canon"
    [ -n "$base" ] && grep -qE '^https?://' <<<"$canon" && [ "${canon#"$base"}" = "$canon" ] && issue error "$rel" "canonical host differs from $base: $canon"
  fi
  # headings, lang, robots
  [ "$h1" = 0 ] && issue error "$rel" "no <h1>"
  [ "$h1" -gt 1 ] && issue error "$rel" "$h1 <h1> elements (use exactly one)"
  [ -z "$lang" ] && issue warn "$rel" "missing <html lang>"
  [ "$noindex" = 1 ] && issue info "$rel" "noindex ($robots)"
  # social
  [ -z "$ogt" ] && [ "$noindex" = 0 ] && issue warn "$rel" "missing og:title"
  [ -z "$ogd" ] && [ "$noindex" = 0 ] && issue warn "$rel" "missing og:description"
  [ -z "$ogi" ] && [ "$noindex" = 0 ] && issue warn "$rel" "missing og:image"
  [ -n "$ogi" ] && ! grep -qE '^https?://' <<<"$ogi" && issue warn "$rel" "og:image is not an absolute URL: $ogi"
  # structured data
  while IFS= read -r j; do
    [ -n "$j" ] || continue
    if ! jq -e . >/dev/null 2>&1 <<<"$j"; then issue error "$rel" "invalid JSON-LD (does not parse)"; continue; fi
    jq -e 'if type=="array" then all(.[]; has("@type")) else (has("@type") or has("@graph")) end' >/dev/null 2>&1 <<<"$j" || issue error "$rel" "JSON-LD without @type"
    jq -e 'if type=="array" then true else has("@context") end' >/dev/null 2>&1 <<<"$j" || issue error "$rel" "JSON-LD without @context"
  done <<<"$lds"
  # hreflang
  while IFS=$'\t' read -r hl href; do
    [ -n "$hl" ] || continue
    grep -qE '^https?://' <<<"$href" || issue error "$rel" "hreflang $hl href is not absolute: $href"
    grep -qiE '^(x-default|[a-z]{2,3}(-[a-z]{2}|-[a-z]{4})?)$' <<<"$hl" || issue error "$rel" "invalid hreflang code: $hl"
    printf '%s\t%s\t%s\n' "$canon" "$hl" "$href" >> "$alts"
  done <<<"$alts_page"
  [ -n "$alts_page" ] && ! grep -qi '^x-default' <<<"$alts_page" && issue warn "$rel" "hreflang set has no x-default"

  printf '%s\t%s\t%s\t%s\t%s\n' "$rel" "$canon" "$noindex" "$title" "$desc" >> "$pages"
done < <(find "$dir" -name '*.html' -type f | sort)

[ "$n" -gt 0 ] || { echo "No HTML pages found in $dir"; exit 0; }

# duplicates across indexable pages
awk -F'\t' '$3==0 && $4!="" {c[$4]++; f[$4]=f[$4] (f[$4]?", ":"") $1} END {for (t in c) if (c[t]>1) print t "\t" f[t]}' "$pages" | while IFS=$'\t' read -r t files; do issue error "site" "duplicate title \"$t\" on: $files"; done
awk -F'\t' '$3==0 && $5!="" {c[$5]++; f[$5]=f[$5] (f[$5]?", ":"") $1} END {for (t in c) if (c[t]>1) print t "\t" f[t]}' "$pages" | while IFS=$'\t' read -r t files; do issue warn "site" "duplicate meta description on: $files"; done
dup_titles=$(awk -F'\t' '$3==0 && $4!="" {c[$4]++} END {n=0; for (t in c) if (c[t]>1) n++; print n}' "$pages")
errors=$((errors + dup_titles))
dup_desc=$(awk -F'\t' '$3==0 && $5!="" {c[$5]++} END {n=0; for (t in c) if (c[t]>1) n++; print n}' "$pages")
warns=$((warns + dup_desc))

# hreflang reciprocity: if page A lists page B (both in this build), B must list A back
while IFS=$'\t' read -r src hl href; do
  [ -n "$src" ] && [ "$href" != "$src" ] || continue
  awk -F'\t' -v h="$href" '$2==h {f=1} END {exit !f}' "$pages" || continue
  awk -F'\t' -v s="$href" -v t="$src" '$1==s && $3==t {f=1} END {exit !f}' "$alts" || issue error "site" "hreflang not reciprocal: $href does not link back to $src"
done < "$alts"

# robots.txt
if [ -f "$dir/robots.txt" ]; then
  awk 'BEGIN{IGNORECASE=1} tolower($0) ~ /^user-agent:[[:space:]]*\*/ {a=1; next} tolower($0) ~ /^user-agent:/ {a=0} a && tolower($0) ~ /^disallow:[[:space:]]*\/[[:space:]]*$/ {print "x"}' "$dir/robots.txt" | grep -q x && issue error "robots.txt" "Disallow: / blocks the whole site for all crawlers"
  grep -qi '^sitemap:' "$dir/robots.txt" || issue warn "robots.txt" "no Sitemap: line"
else
  issue warn "site" "no robots.txt"
fi

# sitemap coverage
maps=$(find "$dir" -maxdepth 2 -name 'sitemap*.xml' -type f)
if [ -z "$maps" ]; then
  issue warn "site" "no sitemap*.xml"
else
  locs="$TMP/locs"; cat $maps | perl -0777 -ne 'print "$1\n" while /<loc>\s*([^<\s]+)\s*<\/loc>/g' | sort -u > "$locs"
  while IFS=$'\t' read -r rel canon noindex _t _d; do
    [ -n "$canon" ] || continue
    if [ "$noindex" = 0 ] && ! grep -qxF "$canon" "$locs"; then issue warn "$rel" "indexable page not in sitemap: $canon"; fi
    if [ "$noindex" = 1 ] && grep -qxF "$canon" "$locs"; then issue error "$rel" "noindex page is listed in the sitemap: $canon"; fi
  done < "$pages"
fi

echo
echo "Result: $errors error(s), $warns warning(s) across $n page(s)."
[ "$strict" = 1 ] && [ "$errors" -gt 0 ] && exit 1
exit 0
