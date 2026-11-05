#!/usr/bin/env bash
# Report which testing tools a project already has, per folder, and suggest one per gap.
# Usage: test-tools.sh [root]
set -u
ROOT="${1:-.}"
printf '%-9s %-14s %-24s %s\n' dir technique tool status

row() { printf '%-9s %-14s %-24s %s\n' "$1" "$2" "$3" "$4"; }

php() { local d="$1" r="$2" c="$1/composer.json"; [ -f "$c" ] || return 0
  if grep -qE '"pestphp/pest"\s*:\s*"[^"]*(\^|~|>=)?\s*[3-9]' "$c"; then row "$r" mutation "pest --mutate" present
  elif grep -q '"infection/infection"' "$c"; then row "$r" mutation infection present
  else row "$r" mutation "pest --mutate / infection" "missing → Pest 3+ has --mutate; else composer require --dev infection/infection"; fi
  grep -q '"giorgiosironi/eris"' "$c" && row "$r" property eris present || row "$r" property "eris / Pest datasets" "optional"
  grep -q '"laravel/dusk"' "$c" && row "$r" e2e dusk present
}

py() { local d="$1" r="$2" fs=""; for f in pyproject.toml requirements.txt requirements-dev.txt; do [ -f "$d/$f" ] && fs="$fs $d/$f"; done; [ -n "$fs" ] || return 0
  has() { grep -qiE "(^|[\"' ])$1" $fs; }
  if has mutmut; then row "$r" mutation mutmut present; elif has cosmic-ray; then row "$r" mutation cosmic-ray present; else row "$r" mutation mutmut "missing → add mutmut to dev deps"; fi
  has hypothesis && row "$r" property hypothesis present || row "$r" property hypothesis "missing → add hypothesis to dev deps"
  has schemathesis && row "$r" contract schemathesis present || row "$r" contract schemathesis "optional (uvx schemathesis run …)"
  has locust && row "$r" load locust present
}

js() { local d="$1" r="$2" p="$1/package.json"; [ -f "$p" ] || return 0; command -v jq >/dev/null 2>&1 || return 0
  dep() { jq -e --arg k "$1" '(.dependencies // {}) + (.devDependencies // {}) | has($k)' "$p" >/dev/null; }
  dep "@stryker-mutator/core" && row "$r" mutation stryker present || row "$r" mutation stryker "missing → npm i -D @stryker-mutator/core"
  dep fast-check && row "$r" property fast-check present || row "$r" property fast-check "missing → npm i -D fast-check"
  if dep "@playwright/test"; then row "$r" e2e playwright present; elif dep cypress; then row "$r" e2e cypress present; else row "$r" e2e playwright "missing → npm init playwright@latest"; fi
  if dep "@axe-core/playwright" || dep jest-axe || dep vitest-axe; then row "$r" a11y axe present; else row "$r" a11y axe "missing → npm i -D @axe-core/playwright"; fi
  dep "@pact-foundation/pact" && row "$r" contract pact present
}

for sub in . backend api server app web frontend client; do
  d="$ROOT/$sub"; [ -d "$d" ] || continue
  r="$sub"; php "$d" "$r"; py "$d" "$r"; js "$d" "$r"
done
command -v k6 >/dev/null 2>&1 && row "-" load k6 "installed" || row "-" load k6 "not installed (brew install k6)"
command -v oasdiff >/dev/null 2>&1 && row "-" contract oasdiff installed || row "-" contract oasdiff "not installed (brew install oasdiff)"
exit 0
