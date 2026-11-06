#!/usr/bin/env bash
# Summarise a Google Search Console Performance export: trend + drop detection, striking-distance
# queries, low CTR for position, top pages and pages with impressions but no clicks.
# Usage: gsc-report.sh <export.zip | export-dir> [--min-impressions 50] [--top 15]
#   Export: Search Console → Performance → Export → Download CSV (Queries.csv, Pages.csv, Dates.csv).
# Needs: bash, perl, awk (unzip for .zip). Read-only.
set -u
src="${1:-}"; shift || true
min=50; top=15
while [ $# -gt 0 ]; do case "$1" in --min-impressions) min="$2"; shift ;; --top) top="$2"; shift ;; esac; shift; done
[ -n "$src" ] && [ -e "$src" ] || { echo "usage: gsc-report.sh <export.zip|dir> [--min-impressions N] [--top N]"; exit 2; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
if [ -f "$src" ]; then
  command -v unzip >/dev/null || { echo "need unzip for .zip exports"; exit 2; }
  unzip -qo "$src" -d "$TMP/x" || { echo "not a zip: $src"; exit 2; }; dir="$TMP/x"
else dir="$src"; fi

# csv <name> → TSV without header: label clicks impressions ctr(%) position. Handles quotes and "1,234".
csv() {
  local f; f=$(find "$dir" -maxdepth 2 -iname "$1" -type f | head -1)
  [ -n "$f" ] || return 1
  perl -ne '
    next if $. == 1; s/\r?\n$//; s/^\x{FEFF}//; my @c;
    while (/\G(?:"((?:[^"]|"")*)"|([^,]*))(,|$)/g) { my $v = defined $1 ? $1 : $2; $v =~ s/""/"/g; push @c, $v; last if $3 eq "" }
    next unless @c >= 5; my ($l,$cl,$im,$ctr,$pos) = @c[0..4];
    for ($cl,$im) { s/,//g } $ctr =~ s/%//; $ctr =~ s/,/./; $pos =~ s/,/./;
    print join("\t", $l, $cl+0, $im+0, $ctr+0, $pos+0), "\n"' "$f"
}

found=0
# ---------- trend and drops (Dates.csv)
if csv 'Dates.csv' | sort > "$TMP/dates"; [ -s "$TMP/dates" ]; then
  found=1
  echo "== Trend (Dates.csv: $(head -1 "$TMP/dates" | cut -f1) → $(tail -1 "$TMP/dates" | cut -f1); last day may be partial)"
  awk -F'\t' '
    { d[NR]=$1; c[NR]=$2; im[NR]=$3 }
    END {
      n=NR; if (n < 14) { print "  not enough days for a trend (need ≥ 14)"; exit }
      l7c=l7i=p28c=p28i=0; pn=0
      for (i=n-6;i<=n;i++) { l7c+=c[i]; l7i+=im[i] }
      for (i=n-34;i<=n-7;i++) if (i>=1) { p28c+=c[i]; p28i+=im[i]; pn++ }
      l7c/=7; l7i/=7; if (pn) { p28c/=pn; p28i/=pn }
      printf "  last 7 days avg: %.1f clicks, %.0f impressions/day · previous %d days: %.1f clicks, %.0f impressions/day\n", l7c, l7i, pn, p28c, p28i
      if (p28i > 0) {
        ch=(l7i-p28i)*100/p28i; printf "  impressions change: %+.1f%%\n", ch
        if (ch <= -50) print "  DROP: impressions fell by half or more — follow search-console references/diagnose-drops.md before changing content"
      }
      for (i=15;i<=n-2;i++) {
        base=0; for (j=i-14;j<i;j++) base+=im[j]; base/=14
        win=(im[i]+im[i+1]+im[i+2])/3
        if (base >= 20 && im[i] < base*0.5 && im[i+1] < base*0.5 && im[i+2] < base*0.5) { printf "  drop starts %s (next 3 days avg %.0f vs %.0f/day in the 14 days before)\n", d[i], win, base; break }
      }
    }' "$TMP/dates"
  echo
fi

# ---------- queries
if csv 'Queries.csv' > "$TMP/q"; [ -s "$TMP/q" ]; then
  found=1
  echo "== Striking distance (avg position 4–20, ≥ $min impressions) — strengthen these pages first"
  awk -F'\t' -v m="$min" '$5>=4 && $5<=20 && $3>=m' "$TMP/q" | sort -t$'\t' -k3,3nr | head -"$top" |
    awk -F'\t' '{printf "  %-50s pos %5.1f  %7d impr  %5d clicks  CTR %.1f%%\n", substr($1,1,50), $5, $3, $2, $4}'
  [ -n "$(awk -F'\t' -v m="$min" '$5>=4 && $5<=20 && $3>=m' "$TMP/q")" ] || echo "  none"
  echo
  echo "== Low CTR for position (top 10, ≥ $min impressions, CTR under half the benchmark) — rewrite title/description"
  awk -F'\t' -v m="$min" 'BEGIN { split("28 15 11 8 7 5 4 3 3 2.5", b, " ") }
    $3>=m && $5>=1 && $5<=10 { p=int($5+0.5); if (p<1) p=1; if (p>10) p=10
      if ($4 < b[p]/2) printf "%s\t%.1f\t%d\t%.1f\t%s\n", $1, $5, $3, $4, b[p] }' "$TMP/q" > "$TMP/low"
  sort -t$'\t' -k3,3nr "$TMP/low" | head -"$top" | awk -F'\t' '{printf "  %-50s pos %5.1f  %7d impr  CTR %.1f%% (benchmark ~%s%%)\n", substr($1,1,50), $2, $3, $4, $5}'
  [ -s "$TMP/low" ] || echo "  none"
  echo
fi

# ---------- pages
if csv 'Pages.csv' > "$TMP/p"; [ -s "$TMP/p" ]; then
  found=1
  echo "== Top pages by clicks"
  sort -t$'\t' -k2,2nr "$TMP/p" | head -"$top" | awk -F'\t' '{printf "  %-70s %6d clicks %8d impr  pos %5.1f\n", substr($1,1,70), $2, $3, $5}'
  echo
  echo "== Pages with ≥ $min impressions and 0 clicks — check intent match, title, position"
  awk -F'\t' -v m="$min" '$3>=m && $2==0' "$TMP/p" | sort -t$'\t' -k3,3nr | head -"$top" | awk -F'\t' '{printf "  %-70s %8d impr  pos %5.1f\n", substr($1,1,70), $3, $5}'
  [ -n "$(awk -F'\t' -v m="$min" '$3>=m && $2==0' "$TMP/p")" ] || echo "  none"
  echo
fi

[ "$found" = 1 ] || { echo "No Queries.csv, Pages.csv or Dates.csv found in $src"; exit 2; }
exit 0
