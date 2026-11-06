#!/usr/bin/env bash
# Run every check this repo has: manifest validation, each plugin's script tests, hook fuzzing,
# and (with --mutation) mutation testing of the critical hook scripts.
# Usage: tools/run-all-tests.sh [--mutation] [--fuzz N]
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
mutation=0; fuzz_n=100
while [ $# -gt 0 ]; do case "$1" in --mutation) mutation=1 ;; --fuzz) fuzz_n="$2"; shift ;; esac; shift; done
failed=()

step() { printf '\n== %s\n' "$1"; }

if command -v claude >/dev/null 2>&1; then
  step "validate manifests"
  for p in . plugins/*/; do claude plugin validate "$p" >/dev/null 2>&1 && echo "ok  $p" || { echo "FAIL $p"; failed+=("validate $p"); }; done
else
  step "validate manifests (claude CLI not found — JSON syntax only)"
  for f in .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json plugins/*/hooks/hooks.json; do
    [ -f "$f" ] || continue; jq -e . "$f" >/dev/null && echo "ok  $f" || { echo "FAIL $f"; failed+=("json $f"); }
  done
fi

step "plugin script tests"
for t in plugins/*/tests/run.sh tools/bench/tests/run.sh; do
  name=$(basename "$(dirname "$(dirname "$t")")")
  full=$(bash "$t" 2>&1); res=$(printf '%s\n' "$full" | tail -1)
  case "$res" in *" 0 failed") echo "ok  $name: $res" ;; *) echo "FAIL $name: $res"; printf '%s\n' "$full" | grep -A1 '✘'; failed+=("tests $name") ;; esac
done

step "hook fuzzing ($fuzz_n inputs)"
bash tools/fuzz-hooks.sh "$fuzz_n" 42 | tail -1 | tee /dev/stderr | grep -q ' 0 property violations' || failed+=("fuzz")

if [ "$mutation" = 1 ]; then
  step "mutation testing (critical hook scripts)"
  while IFS='|' read -r s t; do
    out=$(bash tools/mutate-bash.sh "$s" "$t"); echo "$out" | head -1
    echo "$out" | grep -q 'survivors:' && { echo "$out" | sed -n '2,$p'; }
  done <<'EOF'
plugins/devops/scripts/infra-guard.sh|bash plugins/devops/tests/run.sh
plugins/collaboration/scripts/git-guard.sh|bash plugins/collaboration/tests/run.sh
plugins/security/scripts/secret-guard.sh|bash plugins/security/tests/run.sh
plugins/security/scripts/patterns.sh|bash plugins/security/tests/run.sh
plugins/agent-ops/scripts/done-gate.sh|bash plugins/agent-ops/tests/run.sh
plugins/agent-ops/scripts/lib.sh|bash plugins/agent-ops/tests/run.sh
plugins/frontend/scripts/ui-patterns.sh|bash plugins/frontend/tests/run.sh
plugins/seo/scripts/seo-scan.sh|bash plugins/seo/tests/run.sh
plugins/seo/scripts/seo-crawl.sh|bash plugins/seo/tests/run.sh
plugins/seo/scripts/gsc-report.sh|bash plugins/seo/tests/run.sh
plugins/seo/scripts/page-speed.sh|bash plugins/seo/tests/run.sh
tools/bench/bench.sh|bash tools/bench/tests/run.sh
plugins/product/scripts/loop.sh|bash plugins/product/tests/run.sh
plugins/backend/scripts/backend-patterns.sh|bash plugins/backend/tests/run.sh
EOF
fi

echo
if [ ${#failed[@]} -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "FAILED: ${failed[*]}"; exit 1; fi
