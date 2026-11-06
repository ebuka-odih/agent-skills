#!/usr/bin/env bash
# Read-only scan of a shadcn/Tailwind frontend: theme setup, component layers, token drift,
# and which UI tooling is present. Usage: ui-scan.sh [web-root]   (default: auto-detect)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ui-patterns.sh
. "$HERE/ui-patterns.sh"

root="${1:-}"
if [ -z "$root" ]; then
  for d in . web frontend client app apps/web; do [ -f "$d/package.json" ] && grep -q '"react"' "$d/package.json" && { root="$d"; break; }; done
fi
[ -n "$root" ] && [ -f "$root/package.json" ] || { echo "No React app found (pass the web folder)."; exit 0; }
cd "$root" || exit 1
gaps=0; gap() { echo "- GAP: $1"; gaps=$((gaps+1)); }
dep() { jq -e --arg k "$1" '(.dependencies // {}) + (.devDependencies // {}) | has($k)' package.json >/dev/null 2>&1; }

echo "# UI scan: $root"
echo
echo "## Theme and tokens"
if [ -f components.json ]; then
  cv=$(jq -r '.tailwind.cssVariables // "unset"' components.json 2>/dev/null)
  echo "- components.json found (style: $(jq -r '.style // "?"' components.json 2>/dev/null), cssVariables: $cv)"
  [ "$cv" = "false" ] && gap "shadcn installed without CSS variables — theming needs token classes"
else gap "no components.json (shadcn not initialised here)"; fi
css=$(jq -r '.tailwind.css // empty' components.json 2>/dev/null)
[ -n "$css" ] && [ -f "$css" ] || css=$(ls src/app/globals.css src/styles/globals.css src/index.css app/globals.css styles/globals.css src/globals.css 2>/dev/null | head -1)
if [ -n "$css" ] && [ -f "$css" ]; then
  echo "- tokens file: $css"
  if grep -q '^[[:space:]]*:root' "$css"; then echo "- token block: :root"
  elif grep -qE '^[[:space:]]*--color-[a-z]' "$css" && grep -q '@theme' "$css"; then echo "- token block: @theme ($(grep -cE '^[[:space:]]*--color-' "$css") colour tokens, Tailwind v4 style)"
  else gap "$css has no token block (:root or @theme with --color-*)"; fi
  # Dark theme can live in any CSS file and be keyed by class, data attribute, custom variant or media query
  DARK_RE='\.dark([^A-Za-z0-9_-]|$)|\[data-[a-z-]*=["'"'"']?dark|@custom-variant[[:space:]]+dark|prefers-color-scheme:[[:space:]]*dark'
  dark_files=$( { echo "$css"; find . \( -path ./node_modules -o -path ./dist -o -path ./public -o -path ./build \) -prune -o -name '*.css' -print 2>/dev/null; } | sed 's#^\./##' | sort -u | while read -r f; do [ -f "$f" ] && grep -qE "$DARK_RE" "$f" && echo "$f"; done | paste -sd, -)
  if [ -n "$dark_files" ]; then
    how=$(cat $(tr ',' ' ' <<<"$dark_files") 2>/dev/null | grep -oE "$DARK_RE" | sed -E 's/\.dark.*/.dark class/; s/\[data-([a-z-]*)=.*/[data-\1] attribute/; s/@custom-variant.*/@custom-variant dark/; s/prefers-color-scheme.*/prefers-color-scheme media query/' | sort -u | paste -sd, -)
    n=$(tr ',' '\n' <<<"$dark_files" | grep -c .); shown=$(tr ',' '\n' <<<"$dark_files" | head -3 | paste -sd, -)
    [ "$n" -gt 3 ] && shown="$shown and $((n-3)) more"
    echo "- dark theme: yes ($(sed 's/,/, /g' <<<"$how"); in $(sed 's/,/, /g' <<<"$shown"))"
  else gap "no dark theme found (.dark, [data-*=dark], @custom-variant dark or prefers-color-scheme)"; fi
  grep -q '@theme' "$css" && echo "- @theme mapping: yes" || echo "- @theme mapping: no (Tailwind v3 config?)"
  for t in success warning; do grep -qE -- "--(color-)?$t:" "$css" || echo "- note: no --$t token (status colours may be hard-coded)"; done
else gap "no global CSS with tokens found"; fi
echo

echo "## Component layers"
ui=$(find . -path ./node_modules -prune -o -type d \( -path '*/components/ui' \) -print 2>/dev/null | head -1)
app=$(find . -path ./node_modules -prune -o -type d \( -path '*/components/app' -o -path '*/components/shared' -o -path '*/components/common' \) -print 2>/dev/null | head -1)
[ -n "$ui" ] && echo "- primitives: $ui ($(find "$ui" -name '*.tsx' | wc -l | tr -d ' ') files)" || gap "no components/ui (shadcn primitives) folder"
[ -n "$app" ] && echo "- app components: $app ($(find "$app" -name '*.tsx' | wc -l | tr -d ' ') files)" || gap "no components/app layer — features use primitives directly, patterns drift"
echo

echo "## Token drift (feature code; components/ui, stories and tests excluded)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then files=$(git ls-files -- '*.tsx' '*.jsx' '*.css' '*.vue' | grep -vE '(^|/)node_modules/')
else files=$(find . -path ./node_modules -prune -o \( -name '*.tsx' -o -name '*.jsx' -o -name '*.css' \) -print); fi
hits=$(for f in $files; do [ -f "$f" ] && awk '{print NR "\t" $0}' "$f" | ui_scan_text "$f"; done)
for k in raw-colour colour-literal arbitrary-value inline-style; do
  c=$(grep -c ": $k: " <<<"$hits"); [ -z "$hits" ] && c=0
  echo "- $k: $c"
  [ "$c" -gt 0 ] && gaps=$((gaps+1))
done
if [ -n "$hits" ]; then
  echo "- top files:"; cut -d: -f1 <<<"$hits" | sort | uniq -c | sort -rn | head -5 | sed 's/^ */    /'
fi
echo

echo "## Tooling"
for pair in "storybook:storybook" "@playwright/test:visual/e2e" "@axe-core/playwright:a11y" "@storybook/addon-a11y:a11y" "msw:network mocks" \
            "@tanstack/react-query:server data" "@tanstack/react-table:tables" "react-hook-form:forms" "zod:validation" \
            "class-variance-authority:variants" "tailwind-merge:cn()" "nuqs:URL state" "lucide-react:icons" "next-themes:dark mode" "size-limit:bundle budget"; do
  d="${pair%%:*}"; what="${pair#*:}"
  if dep "$d"; then echo "- ok   $d ($what)"; else echo "- miss $d ($what)"; fi
done
dep storybook || dep "@storybook/react" || dep "@storybook/react-vite" || gap "no Storybook/stories — component states aren't reviewable"
dep "@axe-core/playwright" || dep "@storybook/addon-a11y" || dep "jest-axe" || dep "vitest-axe" || gap "no automated accessibility checks"
echo
[ -f ../docs/ui/UI.md ] || [ -f docs/ui/UI.md ] && echo "- docs/ui/UI.md present" || gap "no docs/ui/UI.md (ui-system writes it)"
echo
echo "Result: $gaps gap(s)."
exit 0
