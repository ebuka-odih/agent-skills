#!/usr/bin/env bash
# Print the format / lint / types / test commands a project actually uses.
# Usage: project-commands.sh [root]   — scans root and common app subfolders.
set -u
ROOT="${1:-.}"
found=0
emit() { printf '%-10s %-8s %s\n' "$1" "$2" "$3"; found=1; }

php_dir() {
  local d="$1" rel="$2" c="$1/composer.json"
  [ -f "$c" ] || return 0
  if grep -q '"laravel/pint"' "$c" || [ -f "$d/pint.json" ]; then emit "$rel" format "vendor/bin/pint"; fi
  if grep -qE '"(larastan/larastan|nunomaduro/larastan|phpstan/phpstan)"' "$c" || ls "$d"/phpstan.neon* >/dev/null 2>&1; then emit "$rel" types "vendor/bin/phpstan analyse"; fi
  if grep -q '"pestphp/pest"' "$c"; then emit "$rel" test "vendor/bin/pest"
  elif [ -f "$d/artisan" ]; then emit "$rel" test "php artisan test"
  elif grep -q '"phpunit/phpunit"' "$c"; then emit "$rel" test "vendor/bin/phpunit"; fi
}

py_dir() {
  local d="$1" rel="$2" files="" run=""
  for f in pyproject.toml requirements.txt requirements-dev.txt requirements/dev.txt setup.cfg; do [ -f "$d/$f" ] && files="$files $d/$f"; done
  [ -n "$files" ] || return 0
  [ -f "$d/uv.lock" ] && run="uv run "
  [ -f "$d/poetry.lock" ] && run="poetry run "
  has() { grep -qiE "$1" $files 2>/dev/null; }
  if has '(^|[" ])ruff|\[tool\.ruff'; then emit "$rel" format "${run}ruff format ."; emit "$rel" lint "${run}ruff check ."
  elif has '(^|[" ])black'; then emit "$rel" format "${run}black ."; fi
  if has '(^|[" ])mypy|\[tool\.mypy'; then emit "$rel" types "${run}mypy ."
  elif has '(^|[" ])pyright|\[tool\.pyright'; then emit "$rel" types "${run}pyright"; fi
  if has '(^|[" ])pytest|\[tool\.pytest' || [ -d "$d/tests" ]; then emit "$rel" test "${run}pytest -q"; fi
}

js_dir() {
  local d="$1" rel="$2" p="$1/package.json" pm="npm run"
  [ -f "$p" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  [ -f "$d/pnpm-lock.yaml" ] && pm="pnpm"
  [ -f "$d/yarn.lock" ] && pm="yarn"
  { [ -f "$d/bun.lockb" ] || [ -f "$d/bun.lock" ]; } && pm="bun run"
  script() { jq -r --arg k "$1" '.scripts[$k] // empty' "$p"; }
  dep()    { jq -e --arg k "$1" '(.dependencies // {}) + (.devDependencies // {}) | has($k)' "$p" >/dev/null; }
  local s
  for s in format fmt; do [ -n "$(script $s)" ] && { emit "$rel" format "$pm $s"; break; }; done
  if [ -z "$(script format)$(script fmt)" ]; then
    dep "@biomejs/biome" && emit "$rel" format "npx biome format --write ." || { dep prettier && emit "$rel" format "npx prettier --write ."; }
  fi
  if [ -n "$(script lint)" ]; then emit "$rel" lint "$pm lint"; elif dep eslint; then emit "$rel" lint "npx eslint ."; fi
  if [ -n "$(script typecheck)" ]; then emit "$rel" types "$pm typecheck"
  elif [ -n "$(script type-check)" ]; then emit "$rel" types "$pm type-check"
  elif [ -f "$d/tsconfig.json" ]; then emit "$rel" types "npx tsc --noEmit"; fi
  if [ -n "$(script test)" ] && ! script test | grep -q 'no test specified'; then emit "$rel" test "$pm test"
  elif dep vitest; then emit "$rel" test "npx vitest run"; elif dep jest; then emit "$rel" test "npx jest"; fi
}

printf '%-10s %-8s %s\n' "dir" "kind" "command"
for sub in . backend api server app web frontend client; do
  d="$ROOT/$sub"; [ -d "$d" ] || continue
  rel="$sub"; [ "$sub" = "." ] && rel="."
  php_dir "$d" "$rel"; py_dir "$d" "$rel"; js_dir "$d" "$rel"
done
[ "$found" = 1 ] || echo "(no commands detected — check README / Makefile / CI config for how this project runs checks)"
[ -f "$ROOT/Makefile" ] && grep -qE '^(test|lint|check|fmt|format):' "$ROOT/Makefile" && echo "note: Makefile has $(grep -oE '^(test|lint|check|fmt|format):' "$ROOT/Makefile" | tr -d ':' | tr '\n' ' ')targets — prefer them if the README says so"
exit 0
