#!/usr/bin/env bash
# Tests for security scripts. Usage: bash plugins/security/tests/run.sh
# Fake keys are assembled from pieces so this file itself never contains a key-shaped string.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/scripts/secret-guard.sh"; SCAN="$ROOT/scripts/security-scan.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }

STRIPE="sk_""live_""$(printf 'a%.0s' {1..24})"
AWS="AK""IA""ABCDEFGHIJKLMNOP"
GH="gh""p_""$(printf 'b%.0s' {1..36})"
PEM="-----BEGIN ""RSA PRIVATE KEY-----"
ANTH="sk-""ant-""$(printf 'c%.0s' {1..40})"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
R="$TMP/repo"; mkdir -p "$R/config"; cd "$R"; git init -q; printf '.env\n' > .gitignore

decide() { # path content → allow | deny
  local out; out=$(jq -nc --arg p "$R/$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$p, content:$c}}' | bash "$GUARD")
  if [ -z "$out" ]; then echo allow; else jq -r .hookSpecificOutput.permissionDecision <<<"$out"; fi
}
reason() { jq -nc --arg p "$R/$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$p, content:$c}}' | bash "$GUARD" | jq -r .hookSpecificOutput.permissionDecisionReason; }

echo "secret guard"
check "stripe live key in config → deny"        '[ "$(decide config/services.php "'"'"'secret'"'"' => '"'"'$STRIPE'"'"',")" = deny ]'
check "reason names kind + points to .env"      'reason config/services.php "$STRIPE" | grep -q "stripe-live" && reason config/services.php "$STRIPE" | grep -q ".env"'
check "aws key → deny"                          '[ "$(decide app/aws.py "KEY=\"$AWS\"")" = deny ]'
check "github token → deny"                     '[ "$(decide .github/x.yml "token: $GH")" = deny ]'
check "private key → deny"                      '[ "$(decide certs/key.pem "$PEM")" = deny ]'
check "anthropic key → deny"                    '[ "$(decide app/ai.py "k=\"$ANTH\"")" = deny ]'
check "gitignored .env → allow"                 '[ "$(decide .env "STRIPE_SECRET=$STRIPE")" = allow ]'
check ".env.example with real key → deny"       '[ "$(decide .env.example "STRIPE_SECRET=$STRIPE")" = deny ]'
check "unignored .env.production → deny"        '[ "$(decide .env.production "K=$STRIPE")" = deny ] && reason .env.production "K=$STRIPE" | grep -q "isn.t gitignored"'
check "AWS docs EXAMPLE key → allow"            '[ "$(decide README.md "AK""IAIOSFODNN7EXAMPLE")" = allow ]'
check "stripe test key → allow"                 '[ "$(decide config/services.php "sk_""test_abcdefghijklmnopqrstuvwx")" = allow ]'
check "env() reference → allow"                 '[ "$(decide config/services.php "'"'"'secret'"'"' => env('"'"'STRIPE_SECRET'"'"'),")" = allow ]'
edit_out=$(jq -nc --arg p "$R/app/x.ts" --arg c "const k = \"$GH\"" '{tool_name:"Edit", tool_input:{file_path:$p, old_string:"a", new_string:$c}}' | bash "$GUARD" | jq -r .hookSpecificOutput.permissionDecision)
check "Edit new_string scanned → deny"          '[ "$edit_out" = deny ]'
off_out=$(jq -nc --arg p "$R/a.py" --arg c "$AWS" '{tool_name:"Write", tool_input:{file_path:$p, content:$c}}' | SECRET_GUARD=off bash "$GUARD")
check "SECRET_GUARD=off disables"               '[ -z "$off_out" ]'

echo "security scan"
printf '<?php return ["k" => "%s"];\n' "$STRIPE" > config/services.php
printf 'API_KEY=%s\n' "$AWS" > .env.staging
printf 'STRIPE_SECRET=%s\n' "$STRIPE" > .env
printf '{"require":{"laravel/framework":"^12"}}' > composer.json
mkdir -p web; printf '{}' > web/package.json; touch web/pnpm-lock.yaml
git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm "chore: init"
out=$(bash "$SCAN" "$R")
check "tracked .env.staging reported"           'grep -q "TRACKED: .env.staging" <<<"$out"'
check "gitignored .env not reported as tracked" '! grep -q "TRACKED: .env$" <<<"$out"'
check "secret in config reported with line"     'grep -q "config/services.php:1 · stripe-live" <<<"$out"'
check "secret value never printed"              '! grep -q "$STRIPE" <<<"$out" && ! grep -q "$AWS" <<<"$out"'
check "composer audit suggested"                'grep -q "\. : composer audit\|- \.: composer audit" <<<"$out"'
check "pnpm audit for web/"                     'grep -q "web: pnpm audit --prod" <<<"$out"'
check "issue count"                             'grep -q "Result: 2 issue group" <<<"$out"'
C="$TMP/clean"; mkdir -p "$C"; cd "$C"; git init -q; printf 'x\n' > a.txt; printf '{}' > package.json; git add -A; git -c user.name=t -c user.email=t@example.invalid commit -qm "chore: init"
out=$(bash "$SCAN" "$C")
check "clean repo: .env not ignored flagged"    'grep -q "NOT ignored: .env" <<<"$out"'
D="$TMP/docs"; mkdir -p "$D"; cd "$D"; git init -q; printf '# docs\n' > README.md; git add -A; git -c user.name=t -c user.email=t@example.invalid commit -qm "docs: x"
dout=$(bash "$SCAN" "$D")
check "docs-only repo: .gitignore check skipped" 'grep -q "no app manifest" <<<"$dout"'
check "clean repo: no secrets"                  'grep -q "none found in tracked files" <<<"$out"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
