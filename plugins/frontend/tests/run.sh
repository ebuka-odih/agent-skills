#!/usr/bin/env bash
# Tests for frontend scripts. Usage: bash plugins/frontend/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/scripts/ui-hook.sh"; SCAN="$ROOT/scripts/ui-scan.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

h() { jq -nc --arg p "$1" --arg t "$2" '{tool_name:"Edit", tool_input:{file_path:$p, new_string:$t}}' | bash "$HOOK" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
kind() { h "$1" "$2" | grep -oE ': (raw-colour|colour-literal|arbitrary-value|inline-style):' | head -1 | tr -d ': '; }

echo "flags"
check "palette bg-blue-600"            '[ "$(kind src/features/a.tsx "<div className=\"bg-blue-600 p-4\">")" = raw-colour ]'
check "palette text-gray-500"          '[ "$(kind src/features/a.tsx "<p className=\"text-gray-500\">")" = raw-colour ]'
check "palette with opacity"           '[ "$(kind src/a.tsx "className=\"bg-red-500/20\"")" = raw-colour ]'
check "border-l palette"               '[ "$(kind src/a.tsx "className=\"border-l-emerald-400\"")" = raw-colour ]'
check "text-white"                     '[ "$(kind src/a.tsx "className=\"text-white\"")" = raw-colour ]'
check "hex literal in tsx"             '[ "$(kind src/a.tsx "const c = \"#1d4ed8\"")" = colour-literal ]'
check "rgb literal in tsx"             '[ "$(kind src/a.tsx "fill: \"rgb(10, 20, 30)\"")" = colour-literal ]'
check "arbitrary padding"              '[ "$(kind src/a.tsx "className=\"p-[13px]\"")" = arbitrary-value ]'
check "arbitrary text size"            '[ "$(kind src/a.tsx "className=\"text-[15px] font-medium\"")" = arbitrary-value ]'
check "inline style"                   '[ "$(kind src/a.tsx "<div style={{ color: \"red\" }}>")" = inline-style ]'
check "hex in css outside token def"   '[ "$(kind src/app.css ".x { color: #ff0000; }")" = colour-literal ]'
check "message points to tokens"       'h src/a.tsx "className=\"bg-blue-600\"" | grep -q "bg-primary"'
two=$'x\nclassName="bg-blue-600"'
check "names file and line"            'h src/features/orders/table.tsx "$two" | grep -q "table.tsx:2: raw-colour"'

echo "allows"
check "semantic tokens"                '[ -z "$(h src/a.tsx "<div className=\"bg-primary text-primary-foreground border-border\">")" ]'
check "muted + status tokens"          '[ -z "$(h src/a.tsx "className=\"text-muted-foreground bg-warning/15\"")" ]'
check "data-[state] variant"           '[ -z "$(h src/a.tsx "className=\"data-[state=open]:bg-accent\"")" ]'
check "arbitrary with var()"           '[ -z "$(h src/a.tsx "className=\"w-[var(--sidebar-width)]\"")" ]'
check "aria-[] variant"                '[ -z "$(h src/a.tsx "className=\"aria-[invalid=true]:border-destructive\"")" ]'
check "components/ui primitives"       '[ -z "$(h src/components/ui/button.tsx "className=\"bg-blue-600 p-[13px]\"")" ]'
check "stories exempt"                 '[ -z "$(h src/x.stories.tsx "className=\"bg-blue-600\"")" ]'
check "token definitions in css"       '[ -z "$(h src/app/globals.css "  --warning: oklch(0.84 0.16 84);")" ]'
check "comments ignored"               '[ -z "$(h src/a.tsx "// avoid bg-blue-600 here")" ]'
check "non-frontend file ignored"      '[ -z "$(h app/service.py "color = \"#ffffff\"")" ]'
check "word containing palette name"   '[ -z "$(h src/a.tsx "const background = textGray; const slate = 1")" ]'
check "markdown ignored"               '[ -z "$(h docs/ui/UI.md "bg-blue-600")" ]'
wout=$(jq -nc '{tool_name:"Write", tool_input:{file_path:"src/b.tsx", content:"ok\nclassName=\"bg-sky-300\"\n"}}' | bash "$HOOK" | jq -r .hookSpecificOutput.additionalContext)
check "Write content scanned"          'grep -q "b.tsx:2: raw-colour" <<<"$wout"'
off=$(jq -nc '{tool_name:"Edit", tool_input:{file_path:"src/a.tsx", new_string:"bg-blue-600"}}' | UI_TOKEN_CHECK=off bash "$HOOK")
check "UI_TOKEN_CHECK=off disables"    '[ -z "$off" ]'

echo "ui-scan"
W="$TMP/app/web"; mkdir -p "$W/src/components/ui" "$W/src/features/orders" "$W/src/app"
echo '{"dependencies":{"react":"^19","@tanstack/react-query":"^5","class-variance-authority":"^0.7","tailwind-merge":"^3","lucide-react":"^0.5"}}' > "$W/package.json"
echo '{"style":"new-york","tailwind":{"css":"src/app/globals.css","cssVariables":true}}' > "$W/components.json"
printf ':root {\n  --primary: oklch(0.2 0 0);\n}\n@theme inline {\n  --color-primary: var(--primary);\n}\n' > "$W/src/app/globals.css"
printf 'export const Button = () => <button className="bg-primary p-[3px]" />\n' > "$W/src/components/ui/button.tsx"
printf 'export const T = () => <div className="bg-blue-600 p-[13px]" style={{ width: 3 }}>\n<span className="text-gray-500">x</span></div>\n' > "$W/src/features/orders/table.tsx"
out=$(bash "$SCAN" "$W")
check "components.json + cssVariables"  'grep -q "components.json found (style: new-york, cssVariables: true)" <<<"$out"'
check "no dark theme → gap"             'grep -q "no dark theme found" <<<"$out"'
check "@theme detected"                 'grep -q "@theme mapping: yes" <<<"$out"'
check "missing status tokens noted"     'grep -q "no --warning token" <<<"$out"'
check "primitives counted"              'grep -q "primitives: .*components/ui (1 files)" <<<"$out"'
check "no app layer → gap"              'grep -q "no components/app layer" <<<"$out"'
check "raw-colour count 2"              'grep -q "raw-colour: 2" <<<"$out"'
check "arbitrary in feature only (1)"   'grep -q "arbitrary-value: 1" <<<"$out"'
check "inline-style 1"                  'grep -q "inline-style: 1" <<<"$out"'
check "top file is the feature table"   'grep -A1 "top files" <<<"$out" | grep -q "features/orders/table.tsx"'
check "storybook missing → gap"         'grep -q "no Storybook" <<<"$out"'
check "query present"                   'grep -q "ok   @tanstack/react-query" <<<"$out"'
auto=$(cd "$TMP/app" && bash "$SCAN")
check "autodetects web/"                'grep -q "# UI scan: web" <<<"$auto"'
V="$TMP/v4"; mkdir -p "$V/src"; echo '{"dependencies":{"react":"^19"}}' > "$V/package.json"
printf '@import "tailwindcss";\n@theme {\n  --color-primary: oklch(0.2 0 0);\n  --color-success: oklch(0.6 0.15 150);\n}\n.dark {\n  --color-primary: oklch(0.9 0 0);\n}\n' > "$V/src/index.css"
vout=$(bash "$SCAN" "$V")
check "@theme-only tokens accepted"     'grep -q "token block: @theme (" <<<"$vout" && ! grep -q "no token block" <<<"$vout"'
check "--color-success counts"          '! grep -q "no --success token" <<<"$vout"'
echo "dark-theme detection"
mkd() { local d="$TMP/$1"; mkdir -p "$d/src"; echo '{"dependencies":{"react":"^19"}}' > "$d/package.json"; printf ':root {\n  --primary: oklch(0.2 0 0);\n}\n' > "$d/src/index.css"; printf '%b' "$2" > "$d/src/${3:-index.css}"; [ "${3:-}" != "" ] && printf ':root {\n  --primary: oklch(0.2 0 0);\n}\n' > "$d/src/index.css"; echo "$d"; }
d1=$(mkd attr ':root {\n  --primary: red;\n}\nhtml[data-dashboard-theme="dark"] {\n  --primary: blue;\n}\n'); o1=$(bash "$SCAN" "$d1")
check "data attribute dark recognised"   'grep -q "dark theme: yes (\[data-dashboard-theme\] attribute" <<<"$o1" && ! grep -q "no dark theme" <<<"$o1"'
d2=$(mkd variant '@custom-variant dark (&:where([data-theme=dark] *));\n:root {\n  --primary: red;\n}\n'); o2=$(bash "$SCAN" "$d2")
check "@custom-variant dark recognised"  'grep -q "dark theme: yes" <<<"$o2" && grep -q "@custom-variant dark" <<<"$o2"'
d3=$(mkd media ':root {\n  --primary: red;\n}\n@media (prefers-color-scheme: dark) {\n  :root { --primary: blue; }\n}\n'); o3=$(bash "$SCAN" "$d3")
check "prefers-color-scheme recognised"  'grep -q "prefers-color-scheme media query" <<<"$o3"'
d4=$(mkd split 'html.dark {\n  --primary: blue;\n}\n' theme-dark.css); o4=$(bash "$SCAN" "$d4")
check "dark tokens in another css file"   'grep -q "dark theme: yes (.dark class; in src/theme-dark.css)" <<<"$o4"'
check "dark-ish class name not counted"   'd5=$(mkd fake ".darkmode-toggle { color: red; }\n"); ! bash "$SCAN" "$d5" | grep -q "dark theme: yes"'

echo "zsh-safe sourcing"
if command -v zsh >/dev/null 2>&1; then
  zo=$(zsh -c '. "$1"; printf "1\tclassName=\"bg-blue-600\"\n" | ui_scan_text src/a.tsx' _ "$ROOT/scripts/ui-patterns.sh")
  check "ui_scan_text works under zsh"    'grep -q "src/a.tsx:1: raw-colour" <<<"$zo"'
  zc=$(zsh -c 'printf "breakpoint()\n" | bash "$1" --stdin app/x.py' _ "$ROOT/../code-standards/scripts/leftover-scan.sh")
  check "leftover-scan --stdin from zsh"  'grep -q "app/x.py:1: debug" <<<"$zc"'
  check "no shell \$path in scanners"     '! grep -nE "(^|[^A-Za-z_])\\\$path([^A-Za-z_]|$)|local path=|^path=" "$ROOT/scripts/"*.sh "$ROOT/../code-standards/scripts/"*.sh'
else ok "zsh not installed — skipped"; fi

check "no react app → message"          'mkdir -p "$TMP/none" && bash "$SCAN" "$TMP/none" | grep -q "No React app found"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
