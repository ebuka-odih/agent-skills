#!/usr/bin/env bash
# Stop hook — refuses to let the agent end its turn when "done" can't be backed up.
#   Rule 1: .agent-log/GOAL.md is active and has unticked criteria (not marked BLOCKED).
#   Rule 2: the agent edited project files this turn without a goal contract — unless it was a small change
#           (<= 3 files, no schema/dependency/deploy files) whose tests ran after the last edit, or docs only.
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
#   Docs-only edits pass. A SMALL change (<= 3 files, nothing risky) is the fast path from goal-contract: it needs
#   no GOAL.md, only a test command that ran after the last edit. Anything bigger or risky needs a goal.
[ -f "$file" ] || exit 0
TESTS='(^|[^[:alnum:]_])(test|tests|pest|phpunit|jest|vitest|pytest|playwright|rspec|go test|cargo test|swift test|xcodebuild|dotnet test|mix test|make check)([^[:alnum:]_]|$)'
RISKY='(^|/)(migrations?|alembic|database/schema|terraform|k8s|helm|\.github/workflows)/|(^|/)(package\.json|package-lock\.json|pnpm-lock\.yaml|yarn\.lock|composer\.(json|lock)|pyproject\.toml|poetry\.lock|uv\.lock|requirements[^/]*\.txt|Gemfile(\.lock)?|go\.(mod|sum)|Cargo\.(toml|lock)|Package\.(swift|resolved)|Dockerfile[^/]*|(docker-)?compose[^/]*\.ya?ml|\.gitlab-ci\.yml|schema\.prisma|\.env[^/]*)$|\.tf$'
DOCS='\.(md|mdx|markdown|txt|rst|png|jpe?g|gif|svg|webp)$'
IFS=$'\t' read -r edits goal_touched files_json test_after < <(jq -rs --arg tests "$TESTS" '
  (to_entries | map(select(.value.event=="prompt")) | last | .key // -1) as $start |
  [ .[$start+1:][] | select(.event=="tool") ] as $turn |
  ($turn | to_entries | map(select((.value.tool=="Edit" or .value.tool=="Write" or .value.tool=="NotebookEdit") and .value.ok and ((.value.summary|test("/\\.agent-log/"))|not)))) as $ed |
  ($ed | map(.key) | max // -1) as $lastEdit |
  [ ($ed | length),
    ($turn | map(select(.summary|test("GOAL\\.md|\\.agent-log/goals"))) | length),
    ($ed | map(.value.summary) | unique | @json),
    ($turn | to_entries | map(select(.key > $lastEdit and .value.tool=="Bash" and (.value.summary|test($tests;"i")))) | length) ] | @tsv' "$file")

if [ "${edits:-0}" -gt 0 ] && [ "${goal_touched:-0}" -eq 0 ]; then
  nfiles=$(jq -r 'length' <<<"$files_json")
  code_files=$(jq -r '.[]' <<<"$files_json" | grep -viE "$DOCS" || true)
  [ -z "$code_files" ] && exit 0                                    # docs, images: nothing to test
  risky=$(grep -E "$RISKY" <<<"$code_files" | head -3 | tr '\n' ' ' || true)
  if [ "$nfiles" -le 3 ] && [ -z "$risky" ]; then
    if [ "${test_after:-0}" -gt 0 ]; then log_gate fast_path "small" "$nfiles file(s)"; exit 0; fi
    block "fast-path-untested" "edited ${nfiles} file(s)" "Small change (fast path, no GOAL.md needed): run the tests for the module you changed now, and end with what changed plus the test command and its result. If the change grew past 3 files or touches schema, dependencies or deploy files, write a goal with the goal-contract skill instead."
  fi
  why="${nfiles} file(s)"; [ -n "$risky" ] && why="$why, including ${risky% }"
  block "no-goal" "edited ${why}" "You edited ${why} this turn without a goal contract. That is past the fast path (more than 3 files, or schema/dependency/deploy files). Load the goal-contract skill and write .agent-log/GOAL.md from the user's request (verbatim), then load verify-done and check each criterion with fresh evidence before your final message."
fi
exit 0
