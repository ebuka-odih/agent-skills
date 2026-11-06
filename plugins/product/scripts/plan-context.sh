#!/usr/bin/env bash
# SessionStart hook: tell the agent where the project stands, so no session starts from zero.
set -u   # no pipefail: `head -1` cutting a pipeline short is expected here
trap 'exit 0' ERR
exec 2>/dev/null

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=parse.sh
. "$HERE/parse.sh"
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
root="${CLAUDE_PROJECT_DIR:-${cwd:-$PWD}}"
SPEC="$root/docs/spec/SPEC.md"; PLAN="$root/docs/plan/PLAN.md"

if [ ! -f "$SPEC" ] && [ ! -f "$PLAN" ]; then exit 0; fi   # not a spec-driven project: stay silent

if [ -f "$SPEC" ] && [ ! -f "$PLAN" ]; then
  msg="product: docs/spec/SPEC.md exists but there is no docs/plan/PLAN.md. Before building, run the project-plan skill (after system-design if docs/architecture/ARCHITECTURE.md is missing)."
elif [ ! -f "$SPEC" ]; then
  msg="product: docs/plan/PLAN.md exists without docs/spec/SPEC.md. Run product-spec in Recover mode so tasks trace to requirements."
else
  active=$(plan_milestones "$PLAN" | awk -F'\t' '$3=="active"{print $1" — "$2; exit}')
  inprog=$(plan_tasks "$PLAN" | awk -F'\t' '$2=="~"{printf "%s%s · %s", (n++ ? "; " : ""), $3, $4}')
  ready=$(plan_ready "$PLAN" | head -1 | awk -F'\t' '{print $1" · "$2" (covers "$3")"}')
  blocked=$(plan_tasks "$PLAN" | awk -F'\t' '$2=="!"{printf "%s%s — %s", (n++ ? "; " : ""), $3, $7}')
  last=$(awk '/^## Progress log/{on=1; next} /^## /{on=0} on && /^- /' "$PLAN" | tail -1)
  msg="product: spec-driven project. Active milestone: ${active:-none}. In progress: ${inprog:-none}. Next ready task: ${ready:-none}. Blocked: ${blocked:-none}. Last progress: ${last:-none}. When the user asks to build, continue or 'what next', use the next-task skill: one task per goal, tasks come from docs/plan/PLAN.md, update PLAN.md and its progress log when a task closes."
fi

loopnext=$(bash "$HERE/loop.sh" next "$root" 2>/dev/null | head -1)
[ -n "$loopnext" ] && msg="$msg Project loop next: $loopnext (see product:project-loop)."
jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$m}}'
exit 0
