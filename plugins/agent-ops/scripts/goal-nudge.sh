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
  msg="agent-ops: Size the request first. SMALL = a fix or tweak whose expected behaviour the request already states, touching <= ~3 source files, with no schema/migration, public API, auth, money/messages, dependency or deploy change. SMALL -> fast path: no GOAL.md; reproduce or pin the behaviour with one test, make the smallest change in the existing pattern, run that module's tests, and end with what changed + the command you ran and its result. Anything else (or a small task that grows) -> FIRST load the goal-contract skill and write .agent-log/GOAL.md before other edits, and run verify-done before your final message. Pure questions and read-only commands need neither."
fi

jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$m}}'
exit 0
