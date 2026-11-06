#!/usr/bin/env bash
# Outage behaviour check: does the stack fail correctly and get noticed?
# Usage: uptime-scan.sh [dir] [--url https://site] [--strict]
#   Static (dir): 5xx masked as 200 by nginx, SPA fallbacks that make every unknown URL a 200 (soft 404),
#   no health endpoint, containers without healthcheck / restart policy, app servers without a graceful timeout.
#   Live (--url): unknown URL must be 404, a health endpoint must answer 200 quickly.
#   --strict exits 1 on any error.
set -u
dir="."; url=""; strict=0
while [ $# -gt 0 ]; do case "$1" in --url) url="${2%/}"; shift ;; --strict) strict=1 ;; *) dir="$1" ;; esac; shift; done
[ -d "$dir" ] || { echo "usage: uptime-scan.sh [dir] [--url https://site] [--strict]"; exit 2; }
dir="${dir%/}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
out="$TMP/out"; : > "$out"
f() { echo "$1 $2 $3" >> "$out"; }   # severity where message

listing() {
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then git -C "$dir" ls-files
  else (cd "$dir" && find . -type f -not -path './.git/*' -not -path '*/node_modules/*' -not -path '*/vendor/*' | sed 's#^\./##'); fi
}
listing | grep -vE '(^|/)(node_modules|vendor|\.venv|venv|tests?|fixtures)/' > "$TMP/files"
pick() { grep -E "$1" "$TMP/files" || true; }

# ---- nginx: masked 5xx and soft 404s
for c in $(pick '(^|/)(nginx[^/]*\.conf|[^/]*\.nginx|default\.conf|[^/]*/nginx/[^/]+\.conf|sites-(available|enabled)/[^/]+)$'); do
  awk -v path="$c" '
    { L[NR] = $0 }
    match($0, /location[[:space:]]+@[A-Za-z0-9_]+/) { n = substr($0, RSTART, RLENGTH); sub(/.*@/, "", n); cur = n; depth = 0 }
    cur != "" { o = gsub(/\{/, "{"); c2 = gsub(/\}/, "}"); depth += o - c2; body[cur] = body[cur] " " $0; if (depth <= 0 && o + c2 > 0) cur = "" }
    END {
      for (i = 1; i <= NR; i++) {
        l = L[i]; if (l ~ /^[[:space:]]*#/) continue
        if (l ~ /error_page[^;]*5[0-9][0-9]/) {
          if (l ~ /=[[:space:]]*200/) { print "error " path ":" i " U1: error_page turns server errors into 200 — return 503 + Retry-After"; continue }
          if (match(l, /=[[:space:]]*@[A-Za-z0-9_]+/)) { t = substr(l, RSTART, RLENGTH); sub(/.*@/, "", t)
            if (body[t] ~ /index\.html/ && body[t] !~ /return[[:space:]]+5[0-9][0-9]/) print "error " path ":" i " U1: 5xx from the upstream is answered by @" t ", which serves index.html with 200 — outages look like empty pages to users and crawlers; return 503 + Retry-After" }
        }
        if (l ~ /try_files/ && l ~ /\/index\.html[[:space:]]*;/ && l !~ /=404/) print "warn " path ":" i " U2: SPA fallback serves index.html (200) for every unknown URL — soft 404s; return 404 for unknown paths (route list or prerendered 404)"
      }
    }' "$dir/$c" >> "$out"
done

# ---- health endpoint in code
server=$(pick '\.(py|php|js|ts|mjs)$' | head -2000)
if [ -n "$server" ] && (cd "$dir" && printf '%s\n' $server | xargs grep -lE 'FastAPI\(|Flask\(|express\(\)|Illuminate\\|createServer\(|fastify\(' 2>/dev/null | grep -q .); then
  if ! (cd "$dir" && printf '%s\n' $server | xargs grep -lE "\.(get|api_route|route)\([[:space:]]*['\"]/(health|healthz|livez|readyz|ready|up|ping)['\"]|health:[[:space:]]*['\"]/|Route::get\([[:space:]]*['\"]/(health|up|ping)" 2>/dev/null | grep -q .); then
    f warn "app" "U3: no health endpoint (/livez, /readyz or Laravel's health: '/up') — load balancers, deploys and monitors can't tell if it's up"
  fi
fi

# ---- containers
dfs=$(pick '(^|/)Dockerfile[^/]*$'); composes=$(pick '(^|/)(docker-)?compose[^/]*\.ya?ml$')
if [ -n "$dfs" ]; then
  hc=0
  for d in $dfs; do grep -q '^[[:space:]]*HEALTHCHECK' "$dir/$d" && hc=1; done
  for c in $composes; do grep -qE '^[[:space:]]+healthcheck:' "$dir/$c" && hc=1; done
  [ "$hc" = 1 ] || f warn "$(echo "$dfs" | head -1)" "U4: no HEALTHCHECK in any Dockerfile or compose file — a wedged container keeps receiving traffic"
fi
for c in $composes; do
  grep -qE '^services:' "$dir/$c" || continue
  grep -qE '^[[:space:]]+restart:' "$dir/$c" || f warn "$c" "U5: compose services without a restart policy — a crash stays down (restart: unless-stopped)"
done
# ---- graceful shutdown of app servers
for x in $dfs $composes $(pick '(^|/)Procfile$|(^|/)start[^/]*\.sh$'); do
  grep -nE 'uvicorn|gunicorn' "$dir/$x" 2>/dev/null | while IFS=: read -r ln line; do
    case "$line" in
      *uvicorn*) [[ "$line" == *timeout-graceful-shutdown* ]] || echo "info $x:$ln U6: uvicorn without --timeout-graceful-shutdown — deploys cut in-flight requests (set it, and stop_grace_period/terminationGracePeriodSeconds above it)" ;;
      *gunicorn*) [[ "$line" == *graceful-timeout* ]] || echo "info $x:$ln U6: gunicorn without --graceful-timeout — deploys cut in-flight requests" ;;
    esac
  done >> "$out"
done

# ---- live probes
if [ -n "$url" ]; then
  code() { curl -s -o /dev/null -m 15 -w '%{http_code} %{time_total}' "$1" 2>/dev/null || echo "000 0"; }
  read -r c t < <(code "$url/this-page-should-not-exist-$RANDOM$RANDOM")
  case "$c" in
    404|410) echo "  live: unknown URL → $c (good)" ;;
    000) f error "$url" "U7: site did not answer" ;;
    *) f warn "$url" "U7: unknown URL returns $c, not 404 — soft 404s (search engines index junk, real errors hide)" ;;
  esac
  found=""
  for p in /livez /readyz /healthz /health /up; do
    read -r c t < <(code "$url$p")
    if [ "$c" = 200 ]; then found="$p"
      awk -v t="$t" 'BEGIN { exit !(t > 1.0) }' && f warn "$url$p" "U8: health endpoint took ${t}s — keep it under 1s"
      break
    fi
  done
  [ -n "$found" ] && echo "  live: health endpoint $found → 200" || f warn "$url" "U8: no public health endpoint answered 200 (/livez /readyz /healthz /health /up) — external monitors can only watch pages"
fi

n_err=$(grep -c '^error ' "$out"); n_warn=$(grep -c '^warn ' "$out"); n_info=$(grep -c '^info ' "$out")
echo "== uptime-scan: $dir${url:+ · $url}"
for sev in error warn info; do grep "^$sev " "$out" | sed 's/^/  /'; done
echo "Result: $n_err error(s), $n_warn warning(s), $n_info info."
[ "$strict" = 1 ] && [ "$n_err" -gt 0 ] && exit 1
exit 0
