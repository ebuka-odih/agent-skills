#!/usr/bin/env bash
# Stop hook — refuses to let the agent end its turn when "done" can't be backed up.
#   Rule 1: .agent-log/GOAL.md is active and has unticked criteria (not marked BLOCKED).
#   Rule 2: the agent edited project files this turn but never wrote or touched a goal contract.
# Blocks at most once per stop attempt (respects stop_hook_active), so it can never loop.
set -uo pipefail
trap 'exit 0' ERR
exec 2>/dev/null

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"

command -v jq >/dev/null 2>&1 || exit 0
[ "${AGENT_OPS_GATE:-on}" = "off" ] && exit 0

input="$(cat)"
cwd=$(jq -r '.cwd // empty' <<<"$input")
sid=$(jq -r '.session_id // empty' <<<"$input")
already=$(jq -r '.stop_hook_active // false' <<<"$input")

logdir="$(ao_log_dir "$cwd")"
file="$(ao_session_file "$logdir" "$sid")"

log_gate() { # event rule detail
  jq -nc --arg ts "$(ao_now)" --arg sid "$sid" --arg e "$1" --arg r "$2" --arg d "$3" \
    '{ts:$ts, session:$sid, event:$e, rule:$r, unverified:$d}' >> "$file"
}

block() { # rule detail reason
  if [ "$already" = "true" ]; then log_gate gate_released "$1" "$2"; exit 0; fi
  log_gate gate_block "$1" "$2"
  jq -nc --arg r "$3" '{decision:"block", reason:$r}'
  exit 0
}

# Rule 1 — active goal with open criteria.
if [ "$(ao_goal_status "$logdir")" = "active" ]; then
  open=$(ao_goal_open "$logdir")
  if [ "${open:-0}" -gt 0 ]; then
    ids=$(ao_goal_open_ids "$logdir")
    block "open-criteria" "$ids" "Goal in .agent-log/GOAL.md is still active with unverified criteria: ${ids}. Run the verify-done skill: check each criterion with fresh evidence, tick the ones that pass, mark the rest BLOCKED with a reason, and set status to done or partial. Then tell the user plainly what is not done."
  fi
  exit 0
fi

# Rule 2 — edits this turn with no goal contract touched this turn.
[ -f "$file" ] || exit 0
read -r edits goal_touched < <(jq -rs '
  (to_entries | map(select(.value.event=="prompt")) | last | .key // -1) as $start |
  [ .[$start+1:][] | select(.event=="tool") ] as $turn |
  [ ($turn | map(select((.tool=="Edit" or .tool=="Write" or .tool=="NotebookEdit") and .ok and ((.summary|test("/\\.agent-log/"))|not))) | length),
    ($turn | map(select(.summary|test("GOAL\\.md|\\.agent-log/goals"))) | length) ] | @tsv' "$file")

if [ "${edits:-0}" -gt 0 ] && [ "${goal_touched:-0}" -eq 0 ]; then
  block "no-goal" "edited ${edits} file(s)" "You edited ${edits} project file(s) this turn without a goal contract. Load the goal-contract skill and write .agent-log/GOAL.md from the user's request (verbatim), then load verify-done and check each criterion with fresh evidence before your final message."
fi
exit 0
