#!/usr/bin/env bash
# Tests for code-standards scripts. Usage: bash plugins/code-standards/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PC="$ROOT/scripts/project-commands.sh"; LS="$ROOT/scripts/leftover-scan.sh"; HOOK="$ROOT/scripts/leftover-hook.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "project-commands: Laravel"
L="$TMP/laravel"; mkdir -p "$L"; touch "$L/artisan" "$L/phpstan.neon"
echo '{"require":{"laravel/framework":"^12"},"require-dev":{"pestphp/pest":"^3","laravel/pint":"^1","larastan/larastan":"^3"}}' > "$L/composer.json"
out=$(bash "$PC" "$L")
check "pint format"        'grep -qE "^\.  +format +vendor/bin/pint" <<<"$out"'
check "phpstan types"      'grep -q "types    vendor/bin/phpstan analyse" <<<"$out"'
check "pest over artisan"  'grep -q "test     vendor/bin/pest" <<<"$out" && ! grep -q "php artisan test" <<<"$out"'
rm "$L/composer.json"; echo '{"require":{"laravel/framework":"^12"}}' > "$L/composer.json"
check "artisan test fallback" 'bash "$PC" "$L" | grep -q "php artisan test"'

echo "project-commands: FastAPI in backend/ with uv"
F="$TMP/fast"; mkdir -p "$F/backend/tests"; touch "$F/backend/uv.lock"
printf '[project]\ndependencies=["fastapi"]\n[dependency-groups]\ndev=["ruff","mypy","pytest"]\n' > "$F/backend/pyproject.toml"
out=$(bash "$PC" "$F")
check "ruff format via uv"  'grep -q "backend    format   uv run ruff format ." <<<"$out"'
check "ruff lint"           'grep -q "lint     uv run ruff check ." <<<"$out"'
check "mypy types"          'grep -q "types    uv run mypy ." <<<"$out"'
check "pytest"              'grep -q "test     uv run pytest -q" <<<"$out"'
F2="$TMP/fast2"; mkdir -p "$F2/tests"; printf 'fastapi==0.116\npytest==8\n' > "$F2/requirements.txt"
check "requirements.txt + tests/ → pytest, no uv" 'bash "$PC" "$F2" | grep -qE "^\.  +test +pytest -q"'

echo "project-commands: React in web/ with pnpm"
W="$TMP/react"; mkdir -p "$W/web"; touch "$W/web/pnpm-lock.yaml" "$W/web/tsconfig.json"
echo '{"scripts":{"lint":"eslint .","test":"vitest run"},"devDependencies":{"prettier":"^3","vitest":"^3","eslint":"^9","typescript":"^5"}}' > "$W/web/package.json"
out=$(bash "$PC" "$W")
check "prettier (no format script)" 'grep -q "web        format   npx prettier --write ." <<<"$out"'
check "pnpm lint script"    'grep -q "lint     pnpm lint" <<<"$out"'
check "tsc from tsconfig"   'grep -q "types    npx tsc --noEmit" <<<"$out"'
check "pnpm test script"    'grep -q "test     pnpm test" <<<"$out"'
echo '{"scripts":{"test":"echo \"Error: no test specified\" && exit 1"},"devDependencies":{"jest":"^29"}}' > "$W/web/package.json"
check "npm placeholder test ignored → jest" 'bash "$PC" "$W" | grep -q "test     npx jest"'
mkdir -p "$TMP/empty"
check "nothing detected → hint" 'bash "$PC" "$TMP/empty" | grep -q "no commands detected"'

echo "leftover-scan --stdin"
s() { printf '%s\n' "$2" | bash "$LS" --stdin "$1"; }
check "php dd()"                 's app/X.php "    dd(\$booking);" | grep -q "app/X.php:1: debug"'
check "php ->dump() method ok"   '[ -z "$(s app/X.php "    \$query->dump();")" ]'
check "python print"             's app/x.py "    print(result)" | grep -q debug'
check "python print in tests ok" '[ -z "$(s tests/test_x.py "    print(result)")" ]'
check "breakpoint()"             's app/x.py "breakpoint()" | grep -q debug'
check "console.log in tsx"       's src/A.tsx "  console.log(state)" | grep -q debug'
check "debugger"                 's src/a.ts "  debugger;" | grep -q debug'
check "secret"                   's app/x.py "KEY = \"sk-abcdefghijklmnop1234\"" | grep -q secret'
check "local path"               's app/x.py "p = \"/Users/alex/project/data.csv\"" | grep -q local-path'
check "TODO without ticket"      's app/x.py "# TODO fix later" | grep -q todo-without-ticket'
check "XXXX placeholder not a TODO"  '[ -z "$(s app/x.sh "RE=\"xxxx|XXXX|changeme\"")" ]'
check "XXX marker flagged"           's app/x.py "# XXX hack" | grep -q todo-without-ticket'
check "TODO(T7) ok"              '[ -z "$(s app/x.py "# TODO(T7): handle refunds")" ]'
check "clean code → no output"   '[ -z "$(s app/x.py "def ok(): return 1")" ]'

echo "leftover-scan: git added lines only"
R="$TMP/repo"; mkdir -p "$R/app"; cd "$R"; git init -q
printf 'def a():\n    print("old debug")\n' > app/a.py
git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm "chore: init"
printf 'def a():\n    print("old debug")\n\ndef b():\n    breakpoint()\n' > app/a.py
printf 'console.log("new")\n' > app/new.js
out=$(bash "$LS")
check "new breakpoint flagged with line 5" 'grep -q "app/a.py:5: debug" <<<"$out"'
check "pre-existing print not flagged"    '! grep -q "old debug" <<<"$out"'
check "untracked file scanned"            'grep -q "app/new.js:1: debug" <<<"$out"'
cd - >/dev/null

echo "hook"
h() { jq -nc --arg p "$1" --arg t "$2" '{tool_name:"Edit", tool_input:{file_path:$p, new_string:$t}}' | bash "$HOOK"; }
out=$(h app/Http/BookingController.php '    dd($booking->toArray());')
check "hook JSON PostToolUse"     '[ "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" = PostToolUse ]'
check "hook names file + hit"     'jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "BookingController.php" && jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "debug"'
check "hook silent on clean edit" '[ -z "$(h app/x.py "return total")" ]'
check "hook skips markdown"       '[ -z "$(h README.md "console.log(x)")" ]'
wout=$(jq -nc '{tool_name:"Write", tool_input:{file_path:"src/a.ts", content:"const a = 1\nconsole.debug(a)\n"}}' | bash "$HOOK")
check "Write content scanned"     'jq -r .hookSpecificOutput.additionalContext <<<"$wout" | grep -q "src/a.ts:2: debug"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
