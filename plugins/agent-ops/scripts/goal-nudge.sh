#!/usr/bin/env bash
# UserPromptSubmit hook: inject the goal → work → verify loop into the agent's context.
# Prints JSON with additionalContext; never blocks the prompt.
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
logdir="$(ao_project_dir "$cwd")/.agent-log"
status=$(ao_goal_status "$logdir")

if [ "$status" = "active" ]; then
  ids=$(ao_goal_open_ids "$logdir")
  msg="agent-ops: .agent-log/GOAL.md is active (open criteria: ${ids:-none}). If this message changes the goal, update GOAL.md (log it under Changes) or archive it and write a new one with the goal-contract skill. Before your final message, run the verify-done skill."
else
  msg="agent-ops: If this request needs file edits or more than one step, FIRST load the goal-contract skill and write .agent-log/GOAL.md (the request verbatim + checkable acceptance criteria) before any other edit. Before your final message, load the verify-done skill and prove each criterion with fresh evidence. Skip both only for pure questions or a single read-only command."
fi

jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$m}}'
exit 0
