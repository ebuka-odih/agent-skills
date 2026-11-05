#!/usr/bin/env bash
# Tests for testing-plugin scripts. Usage: bash plugins/testing/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAN="$ROOT/scripts/test-plan.sh"; TOOLS="$ROOT/scripts/test-tools.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
G="git -c user.name=t -c user.email=t@example.invalid"

echo "test-plan"
R="$TMP/repo"; mkdir -p "$R"; cd "$R"; git init -q -b main
mkdir -p docs/spec; cat > docs/spec/SPEC.md <<'EOF'
- **R1** (must) Members book classes.
- **NFR1** (must) Booking API p95 < 300 ms at 50 rps.
- **NFR2** (must) Web app meets WCAG 2.2 AA.
EOF
printf 'openapi: 3.1.0\n' > openapi.yaml
$G add -A && $G commit -qm "chore: init"
git switch -q -c feat/T7-cancel
mkdir -p app/services app/api/v1/endpoints web/src/components/ui web/src/pages database/migrations app/agents/concierge tests app/models
touch app/services/fees.py app/api/v1/endpoints/bookings.py web/src/components/ui/Button.tsx web/src/pages/Checkout.tsx \
      database/migrations/2026_11_05_add_fee.php app/agents/concierge/agent.py tests/test_fees.py README.md app/models/label.py
mkdir -p .claude/worktrees/x web/src app/hooks evals/case/resources; touch .claude/worktrees/x/a.py web/src/config.json web/src/styles.css app/hooks/git-guard.sh evals/case/resources/refunds.py
out=$(bash "$PLAN" main)
row() { grep -F "| \`$1\` |" <<<"$out"; }
check "fees.py → mutation + property"          'row app/services/fees.py | grep -q "mutation" && row app/services/fees.py | grep -q "property-based"'
check "endpoint → contract + load NFR1"        'row app/api/v1/endpoints/bookings.py | grep -q "contract diff" && row app/api/v1/endpoints/bookings.py | grep -q "load (NFR1)"'
check "booking endpoint → E2E journey"         'row app/api/v1/endpoints/bookings.py | grep -q "E2E journey"'
check "ui Button → a11y (NFR2) + visual"       'row web/src/components/ui/Button.tsx | grep -q "a11y (NFR2)" && row web/src/components/ui/Button.tsx | grep -q visual'
check "Checkout page → a11y + E2E"             'row web/src/pages/Checkout.tsx | grep -q a11y && row web/src/pages/Checkout.tsx | grep -q "E2E journey"'
check "migration → up/down/up"                 'row database/migrations/2026_11_05_add_fee.php | grep -q "migration up/down/up"'
check "agent → AI evals"                       'row app/agents/concierge/agent.py | grep -q "AI evals"'
check "test file → tests only"                 'row tests/test_fees.py | grep -q "tests only"'
check "dot-folders and config skipped"         '! grep -qE "\.claude/|config\.json|styles\.css" <<<"$out"'
check "guard script → mutation"                'row app/hooks/git-guard.sh | grep -q mutation'
check "eval fixtures skipped"                 '! grep -q "evals/case/resources" <<<"$out"'
check "README skipped"                         '! grep -q "README.md" <<<"$out"'
check "plain model → base only"                'row app/models/label.py | grep -qE "\| unit/feature \(base\) \|$"'
check "summary lists mutation reason"          'grep "^- \*\*mutation testing\*\*" <<<"$out" | grep -q "app/services/fees.py is a critical rule"'
check "conditions line"                        'grep -q "contract file found · load NFRs: NFR1 · a11y NFRs: NFR2" <<<"$out"'

R2="$TMP/small"; mkdir -p "$R2/app/models"; cd "$R2"; git init -q -b main; touch app/models/x.py; $G add -A; $G commit -qm "chore: init"
git switch -q -c fix/label; printf 'label = "Book"\n' > app/models/x.py
out=$(bash "$PLAN" main)
check "small change → nothing extra"           'grep -q "Nothing — unit/feature tests" <<<"$out"'
$G commit -qam "fix: label"; git switch -q main; out=$(bash "$PLAN" main)
check "no changes → message"                   'grep -q "No changed files" <<<"$out"'

echo "test-tools"
T="$TMP/tools"; mkdir -p "$T/backend" "$T/web"
echo '{"require-dev":{"pestphp/pest":"^3.5"}}' > "$T/composer.json"
printf '[dependency-groups]\ndev=["pytest","hypothesis","mutmut"]\n' > "$T/backend/pyproject.toml"
echo '{"devDependencies":{"@playwright/test":"^1","fast-check":"^3"}}' > "$T/web/package.json"
out=$(bash "$TOOLS" "$T")
check "pest 3 → pest --mutate present"         'grep -qE "^\.  .*mutation .*pest --mutate +present" <<<"$out"'
check "python hypothesis + mutmut present"     'grep -qE "^backend +property +hypothesis +present" <<<"$out" && grep -qE "^backend +mutation +mutmut +present" <<<"$out"'
check "web playwright + fast-check present"    'grep -qE "^web +e2e +playwright +present" <<<"$out" && grep -qE "^web +property +fast-check +present" <<<"$out"'
check "web stryker missing with install hint"  'grep -qE "^web +mutation +stryker +missing → npm i -D @stryker-mutator/core" <<<"$out"'
check "web axe missing"                        'grep -qE "^web +a11y +axe +missing" <<<"$out"'
echo '{"require-dev":{"pestphp/pest":"^2.0"}}' > "$T/composer.json"
out=$(bash "$TOOLS" "$T")
check "pest 2 → mutation missing"              'grep -qE "^\.  .*mutation .*missing" <<<"$out"'
check "k6 + oasdiff rows present"              'grep -qE "^- +load +k6" <<<"$out" && grep -qE "^- +contract +oasdiff" <<<"$out"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
