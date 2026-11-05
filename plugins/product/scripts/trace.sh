#!/usr/bin/env bash
# Project status + requirement traceability.
# Usage: trace.sh [docs/spec/SPEC.md] [docs/plan/PLAN.md]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=parse.sh
. "$HERE/parse.sh"

SPEC="${1:-docs/spec/SPEC.md}"
PLAN="${2:-docs/plan/PLAN.md}"
[ -f "$SPEC" ] || { echo "No spec at $SPEC — run the product-spec skill."; exit 0; }
[ -f "$PLAN" ] || { echo "Spec found, no plan at $PLAN — run the project-plan skill."; exit 0; }

tasks="$(plan_tasks "$PLAN")"
reqs="$(spec_requirements "$SPEC")"
deferred=" $(plan_deferred "$PLAN" | tr '\n' ' ') "

echo "# Project status"
echo
active=$(plan_milestones "$PLAN" | awk -F'\t' '$3=="active"{print $1"\t"$2; exit}')
if [ -n "$active" ]; then
  aid=${active%%$'\t'*}; aname=${active#*$'\t'}
  total=$(awk -F'\t' -v m="$aid" '$1==m && $2!="-"' <<<"$tasks" | grep -c . || true)
  donec=$(awk -F'\t' -v m="$aid" '$1==m && $2=="x"' <<<"$tasks" | grep -c . || true)
  echo "Active milestone: $aid — $aname ($donec/$total tasks done)"
else
  echo "Active milestone: none — set one to 'status: active' in PLAN.md"
fi
echo "Milestones: $(plan_milestones "$PLAN" | awk -F'\t' '{printf "%s[%s] ", $1, $3}')"
echo

echo "## In progress"
awk -F'\t' '$2=="~"{print "- " $3 " · " $4 (length($7)? " — " $7 : "")}' <<<"$tasks" | grep . || echo "- none"
echo
echo "## Next ready"
plan_ready "$PLAN" | head -3 | awk -F'\t' '{print "- " $1 " · " $2 " (covers " $3 ")"}' | grep . || echo "- none"
echo
echo "## Blocked"
awk -F'\t' '$2=="!"{print "- " $3 " · " $4 " — " $7}' <<<"$tasks" | grep . || echo "- none"
echo

echo "## Requirements"
must=0; met=0; uncovered=""
while IFS=$'\t' read -r rid pri st; do
  [ -n "$rid" ] || continue
  case "$st" in dropped*) continue ;; esac
  [ "$pri" = "must" ] && must=$((must+1))
  [ "$st" = "met" ] && met=$((met+1))
  covered=$(awk -F'\t' -v r="$rid" '$2!="-" { n=split($5,c,","); for(i=1;i<=n;i++) if (c[i]==r) { print $3; break } }' <<<"$tasks" | head -1)
  if [ -z "$covered" ]; then
    case "$deferred" in *" $rid "*) ;; *) uncovered="$uncovered $rid($pri)" ;; esac
  fi
done <<<"$reqs"
echo "- must: $must · met: $met"
echo "- uncovered:${uncovered:- none}"
orphans=$(awk -F'\t' '$2!="-" && ($5=="-" || $5=="")' <<<"$tasks" | awk -F'\t' '{printf "%s ", $3}')
echo "- tasks covering nothing: ${orphans:-none}"
dangling=""
while IFS=$'\t' read -r ms mark tid title covers deps note; do
  [ -n "$tid" ] || continue
  IFS=',' read -ra cs <<<"$covers"
  for c in "${cs[@]}"; do
    case "$c" in setup|-|"") continue ;; esac
    grep -q "^$c"$'\t' <<<"$reqs" || dangling="$dangling $tid→$c"
  done
done <<<"$tasks"
echo "- tasks pointing at unknown requirements:${dangling:- none}"
echo
echo "## Last progress"
awk '/^## Progress log/{on=1; next} /^## /{on=0} on && /^- /' "$PLAN" | tail -3 | grep . || echo "- none yet"
