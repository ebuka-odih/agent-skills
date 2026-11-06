#!/usr/bin/env bash
# Scan a backend codebase for production risks: unsafe migrations, unbounded jobs, HTTP calls without
# timeouts, overlapping or undeployed schedulers, event-loop misuse.
# Usage: backend-scan.sh [dir] [--strict] [--all]
#   --all     include migrations already applied long ago (default: only the 30 newest migration files)
#   --strict  exit 1 when any error is found
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=backend-patterns.sh
. "$HERE/backend-patterns.sh"
dir="."; strict=0; all=0
for a in "$@"; do case "$a" in --strict) strict=1 ;; --all) all=1 ;; *) dir="$a" ;; esac; done
[ -d "$dir" ] || { echo "usage: backend-scan.sh [dir] [--strict] [--all]"; exit 2; }
dir="${dir%/}"

files() {
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then git -C "$dir" ls-files | sed "s#^#$dir/#"
  else find "$dir" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/vendor/*'; fi
}
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
files | grep -E '\.(php|py|sql|ts|js)$' > "$TMP/all"
# newest migrations only (old ones already ran; their risks are history) unless --all
grep -E 'database/migrations/|migrations/versions/|alembic/versions/|/migrations/' "$TMP/all" | sort > "$TMP/mig"
if [ "$all" = 0 ]; then tail -30 "$TMP/mig" > "$TMP/mig.keep"; else cp "$TMP/mig" "$TMP/mig.keep"; fi
grep -vxF -f "$TMP/mig" "$TMP/all" > "$TMP/code" 2>/dev/null || cp "$TMP/all" "$TMP/code"
cat "$TMP/mig.keep" "$TMP/code" > "$TMP/scan"

: > "$TMP/out"
while IFS= read -r f; do
  be_scan_file "${f#"$dir"/}" "$f" >> "$TMP/out"
done < "$TMP/scan"
be_scan_repo "$dir" >> "$TMP/out"

n_err=$(grep -c '^error ' "$TMP/out"); n_warn=$(grep -c '^warn ' "$TMP/out"); n_info=$(grep -c '^info ' "$TMP/out")
echo "== backend-scan: $dir ($(grep -c . "$TMP/scan") files; $(grep -c . "$TMP/mig.keep") of $(grep -c . "$TMP/mig") migrations)"
for sev in error warn info; do grep "^$sev " "$TMP/out" | sed 's/^/  /'; done
echo
echo "By rule:"; sed -E 's/^[a-z]+ [^ ]+ ([A-Z][0-9]):.*/\1/' "$TMP/out" | sort | uniq -c | sort -rn | sed 's/^/  /'
echo "Result: $n_err error(s), $n_warn warning(s), $n_info info."
[ "$strict" = 1 ] && [ "$n_err" -gt 0 ] && exit 1
exit 0
