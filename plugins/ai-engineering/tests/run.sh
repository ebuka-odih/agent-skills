#!/usr/bin/env bash
# Tests for ai-engineering hook script. Usage: bash plugins/ai-engineering/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/scripts/ai-context.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
run() { CLAUDE_PROJECT_DIR="$1" bash "$HOOK" <<<'{}'; }
ctx() { jq -r '.hookSpecificOutput.additionalContext // empty' <<<"$1"; }

echo "no AI"
mkdir -p "$TMP/plain"; echo '{"require":{"laravel/framework":"^12"}}' > "$TMP/plain/composer.json"
check "silent when project has no AI"          '[ -z "$(run "$TMP/plain")" ]'

echo "AI deps but no AI.md"
mkdir -p "$TMP/py/backend"; printf 'fastapi==0.116\npydantic-ai-slim[openai]==1.107\n' > "$TMP/py/backend/requirements.txt"
out=$(run "$TMP/py")
check "valid hook JSON"                         '[ "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" = "SessionStart" ]'
check "pydantic-ai → asks for Recover mode"    'ctx "$out" | grep -q "ai-design skill in Recover mode"'
mkdir -p "$TMP/lv"; echo '{"require":{"laravel/ai":"^0.9"}}' > "$TMP/lv/composer.json"
check "laravel/ai → asks for Recover mode"     'ctx "$(run "$TMP/lv")" | grep -q "Recover mode"'

echo "drift checks"
P="$TMP/proj"; mkdir -p "$P/docs/ai/features" "$P/docs/spec" "$P/evals/ai/F1"
cat > "$P/docs/ai/AI.md" <<'EOF'
---
spec_version: 2
---
# X — AI architecture
## Features
| ID | Feature | Serves | Pattern | Tier | Runs | Card | Status |
|---|---|---|---|---|---|---|---|
| F1 | Extract | R4 | extraction | standard | queued | x | live |
| F2 | Chat | R6 | chat | standard | stream | x | building |
## Where AI code lives
EOF
touch "$P/docs/ai/features/F1-extract.md"
printf -- '---\nstatus: agreed\nversion: 3\n---\n' > "$P/docs/spec/SPEC.md"
cat > "$P/docs/ai/LEARNINGS.md" <<'EOF'
## L2 — 2026-11-05 · retry on 402
- scope: house-candidate
- status: applied
## L1 — 2026-11-01 · schema validation
- scope: house-candidate
- status: promoted: 2026-11-02
EOF
c=$(ctx "$(run "$P")")
check "spec version drift reported (3 vs 2)"   'grep -q "SPEC.md is version 3 but AI.md was checked against 2" <<<"$c"'
check "F2 has no card"                          'grep -q "Features without a card: F2" <<<"$c"'
check "F1 has card (not reported)"              '! grep -q "card: F1" <<<"$c"'
check "F2 has no eval set"                      'grep -q "without an eval set (evals/ai/<F-id>/): F2" <<<"$c"'
check "1 unpromoted house-candidate"            'grep -q "1 house-candidate learning" <<<"$c"'

echo "clean project"
sed -i.bak 's/^spec_version: 2/spec_version: 3/' "$P/docs/ai/AI.md"; touch "$P/docs/ai/features/F2-chat.md"; mkdir -p "$P/evals/ai/F2"
printf '## L2 — x\n- scope: project\n' > "$P/docs/ai/LEARNINGS.md"
check "no drift → silent"                       '[ -z "$(run "$P")" ]'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
