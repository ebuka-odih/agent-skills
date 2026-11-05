#!/usr/bin/env bash
# Recommend test techniques for the current change from its conditions.
# Reads changed files (vs base, + working tree + untracked) and docs/spec/SPEC.md NFRs.
# Usage: test-plan.sh [base-ref]   (default origin/main → main → HEAD)
set -u
base="${1:-}"
if [ -z "$base" ]; then
  for b in origin/main main origin/master master; do git rev-parse --verify -q "$b" >/dev/null && { base=$b; break; }; done
fi
mb=$(git merge-base "${base:-HEAD}" HEAD 2>/dev/null || echo HEAD)
files=$( { git diff --name-only "$mb"...HEAD 2>/dev/null; git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | sort -u | grep .)
[ -n "$files" ] || { echo "No changed files vs ${base:-HEAD}."; exit 0; }

SPEC=docs/spec/SPEC.md
nfr_load=""; nfr_a11y=""
if [ -f "$SPEC" ]; then
  nfr_load=$(grep -E '^\s*- \*\*NFR[0-9]+\*\*' "$SPEC" | grep -iE 'p9[59]|latency|[0-9]+ ?ms|rps|req/s|throughput|load' | grep -oE 'NFR[0-9]+' | paste -sd, -)
  nfr_a11y=$(grep -E '^\s*- \*\*NFR[0-9]+\*\*' "$SPEC" | grep -iE 'wcag|accessib|a11y|screen reader' | grep -oE 'NFR[0-9]+' | paste -sd, -)
fi
has_contract=0
for c in openapi.yaml openapi.yml openapi.json docs/openapi.yaml api/openapi.yaml schema.graphql; do [ -f "$c" ] && has_contract=1; done
ls ./*/openapi.* >/dev/null 2>&1 && has_contract=1
grep -rqlE 'FastAPI\(' --include=*.py . 2>/dev/null && has_contract=1   # FastAPI publishes OpenAPI

CRIT='pay|billing|invoice|refund|charge|price|pricing|fee|tax|discount|coupon|money|wallet|ledger|payout|auth|login|password|permission|polic|role|tenant|quota|subscription|entitle|guard|gate|redact|secret|sanitiz|validat'
PURE='(^|/)(services?|domain|actions?|lib|utils?|rules?|calculat|pricing|billing|scripts)(/|$)|_service\.|Service\.php$|Action\.php$'
INPUTY='money|price|fee|tax|discount|date|time|tz|parse|format|valid|serial|slug|sort|rank|split|round|currency|amount|schedule|scan|pattern|guard|trace'
JOURNEY='checkout|booking|book|signup|sign-up|register|login|onboard|payment|pay|cart|order'

# bash 3.2 (macOS) has no associative arrays: collect "technique<TAB>reason" lines instead
rows=(); why=""
add() { why="$why$1	$2
"; }

while IFS= read -r f; do
  t=""
  lf=$(tr 'A-Z' 'a-z' <<<"$f")
  case "$lf" in
    .*|*/.*/*) continue ;;                                   # dot-folders: tooling, worktrees, editor state
    */evals/*|evals/*|*/fixtures/*|fixtures/*|*/testdata/*) continue ;;   # eval/test fixtures are data
    *.md|*.txt|*.lock|*lock.json|*.lock.yaml|*.png|*.jpg|*.jpeg|*.gif|*.webp|*.svg|*.ico|*.woff*|*.ttf|*.pdf) continue ;;
    *.json|*.ndjson|*.yml|*.yaml|*.toml|*.ini|*.cfg|*.env*|*.csv|*.css|*.scss|*.map|docs/*|.github/*) continue ;;
    *.pptx|*.docx|*.xlsx|*.zip|*.gz|*.mp4|*.mov|*.mp3|*.wav|*.sqlite|*.db) continue ;;
  esac
  if grep -qiE '(^|/)(tests?|__tests__|spec|e2e)/|(_test|\.test|\.spec|test)\.(py|php|ts|tsx|js)$|test_[a-z0-9_]+\.py$' <<<"$f"; then
    rows+=("$f|tests only — run them; check they'd fail without the change"); continue
  fi
  t="unit/feature (base)"
  if grep -qE "(^|/)(migrations?|alembic/versions)/" <<<"$lf"; then
    t="$t, migration up/down/up"; add "migration test" "$f"
  fi
  if grep -qiE '(^|/)(ai|agents?|prompts?|llm)/|embedding' <<<"$lf"; then
    t="$t, AI evals"; add "AI evals (ai-engineering ai-evals)" "$f"
  fi
  if grep -qE "$CRIT" <<<"$lf"; then
    t="$t, mutation (critical rule)"; add "mutation testing" "$f is a critical rule"
  fi
  if grep -qE "$PURE" <<<"$f" && grep -qE "$INPUTY|$CRIT" <<<"$lf"; then
    t="$t, property-based"; add "property-based" "$f is pure logic over many inputs"
  fi
  if grep -qiE '(^|/)(controllers?|endpoints?|routers?|routes|api)(/|\.php$)|controller\.php$' <<<"$f"; then
    if [ "$has_contract" = 1 ]; then t="$t, contract diff"; add "contract testing" "$f changes an API with a published contract"; fi
    if [ -n "$nfr_load" ]; then t="$t, load (${nfr_load})"; add "load test (k6)" "$f is on a path with NFR $nfr_load"; fi
  fi
  if grep -qiE '\.(tsx|jsx|vue|svelte)$|\.blade\.php$|(^|/)(components?|pages|views|screens)/' <<<"$f"; then
    t="$t, component + a11y${nfr_a11y:+ ($nfr_a11y)}"; add "accessibility (axe)" "$f is UI"
    if grep -qiE '(^|/)(components/ui|ui/|design-system|ds)/' <<<"$f"; then t="$t, visual"; add "visual regression" "$f is a shared component"; fi
  fi
  if grep -qiE "$JOURNEY" <<<"$lf" && grep -qiE '\.(tsx|jsx|vue|svelte)$|\.blade\.php$|controller|endpoint|route' <<<"$lf"; then
    t="$t, E2E journey"; add "E2E (critical journey)" "$f touches a must-have journey"
  fi
  rows+=("$f|$t")
done <<<"$files"

echo "# Test plan for changes vs ${base:-HEAD}"
echo
echo "| File | Techniques |"
echo "|---|---|"
for r in ${rows[@]+"${rows[@]}"}; do echo "| \`${r%%|*}\` | ${r#*|} |"; done
echo
echo "## Add beyond the base layer"
if [ -z "$why" ]; then
  echo "- Nothing — unit/feature tests (code-standards testing) are enough for this change."
else
  printf '%s' "$why" | awk -F'\t' 'NF==2 { if (!($1 in r)) { order[++n]=$1; r[$1]=$2 } else r[$1]=r[$1] "; " $2 }
    END { for (i=1;i<=n;i++) { k=split(r[order[i]], parts, "; "); line=parts[1]
            for (j=2; j<=k && j<=3; j++) line=line "; " parts[j]
            if (k>3) line=line "; and " (k-3) " more"
            print "- **" order[i] "** — " line } }' | sort
fi
echo
echo "Conditions: contract file $( [ $has_contract = 1 ] && echo found || echo none ) · load NFRs: ${nfr_load:-none} · a11y NFRs: ${nfr_a11y:-none}"
echo "Budget: mutation/contract on PR for changed files; load nightly on staging; E2E smoke ≤ 5 min (test-strategy budget.md)."
exit 0
