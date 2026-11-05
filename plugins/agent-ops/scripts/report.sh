#!/usr/bin/env bash
# Summarise one .agent-log session file. Usage: report.sh <session.jsonl>
set -euo pipefail
f="${1:?usage: report.sh <session.jsonl>}"
[ -f "$f" ] || { echo "No such file: $f" >&2; exit 1; }

echo "# Session report: $(basename "$f")"
echo
echo "## Requests"
jq -r 'select(.event=="prompt") | "- [\(.ts)] \(.prompt | gsub("\n"; " ") | .[0:200])"' "$f"
echo
echo "## Activity"
jq -rs '[.[] | select(.event=="tool")] | group_by(.tool) | map("- \(.[0].tool): \(length) calls, \(map(select(.ok==false))|length) failed") | .[]' "$f"
echo
echo "## Files written or edited"
jq -rs '[.[] | select(.event=="tool" and (.tool=="Edit" or .tool=="Write" or .tool=="NotebookEdit") and .ok) | .summary] | unique | .[] | "- \(.)"' "$f"
echo
echo "## Failed tool calls"
jq -r 'select(.event=="tool" and .ok==false) | "- [\(.ts)] \(.tool): \(.summary | .[0:160])"' "$f"
echo
echo "## Done-gate"
jq -r 'select(.event=="gate_block" or .event=="gate_released") | "- [\(.ts)] \(.event): \(.unverified)"' "$f"
echo
echo "## Final claims"
jq -r 'select(.event=="stop") | "- [\(.ts)] goal=\(.goal_status) open=\(.goal_open_criteria): \(.claim | gsub("\n"; " ") | .[0:240])"' "$f"
echo
echo "## Gap signals"
# Claimed tests/done after the last edit without a later test-like command.
jq -rs '
  # Order by line position, not timestamp: many events share the same second.
  to_entries as $e |
  ([$e[] | select(.value.event=="tool" and (.value.tool=="Edit" or .value.tool=="Write")) | .key] | max) as $lastEdit |
  ([$e[] | select(.value.event=="tool" and .value.tool=="Bash" and (.value.summary|test("test|pest|phpunit|jest|vitest|pytest|go test|cargo test";"i"))) | .key] | max) as $lastTest |
  ([$e[] | select(.value.event=="stop") | .value] | last) as $stop |
  [
    (if $stop and ($stop.claim|test("tests? pass|all tests|tested";"i")) and ($lastTest == null or ($lastEdit != null and $lastTest < $lastEdit))
      then "- Claims tests pass, but no test command ran after the last edit" else empty end),
    (if $stop and ($stop.claim|test("\\bdone\\b|complete|finished";"i")) and ($stop.goal_status != "done")
      then "- Claims done, but goal status is \($stop.goal_status)" else empty end),
    (if ([$e[] | select(.value.event=="gate_released")] | length) > 0
      then "- Agent stopped with unverified criteria after the gate released" else empty end)
  ] | if length == 0 then "- none found" else .[] end' "$f"
