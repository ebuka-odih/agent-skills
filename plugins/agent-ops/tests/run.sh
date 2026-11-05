#!/usr/bin/env bash
# Tests for agent-ops hook scripts. Feeds fake hook payloads, checks the log and gate output.
# Usage: bash plugins/agent-ops/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$ROOT/scripts/log-event.sh"
GATE="$ROOT/scripts/done-gate.sh"
REPORT="$ROOT/scripts/report.sh"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }

PROJ="$(mktemp -d)"; trap 'rm -rf "$PROJ"' EXIT
export CLAUDE_PROJECT_DIR="$PROJ"
SID="abcdef12-3456-7890"
send() { printf '%s' "$1" | bash "$2"; }
logfile() { ls "$PROJ"/.agent-log/sessions/*.jsonl 2>/dev/null | head -1; }

echo "logging"
send '{"hook_event_name":"SessionStart","session_id":"'$SID'","cwd":"'$PROJ'","source":"startup"}' "$LOG"
check "creates session log"            '[ -f "$(logfile)" ]'
check "creates .gitignore for sessions" 'grep -q "^sessions/$" "$PROJ/.agent-log/.gitignore"'
check "session_start event"            'jq -e "select(.event==\"session_start\")" "$(logfile)" >/dev/null'

send '{"hook_event_name":"UserPromptSubmit","session_id":"'$SID'","cwd":"'$PROJ'","prompt":"add a health endpoint"}' "$LOG"
check "prompt recorded verbatim"       'jq -e "select(.event==\"prompt\" and .prompt==\"add a health endpoint\")" "$(logfile)" >/dev/null'

send '{"hook_event_name":"PostToolUse","session_id":"'$SID'","cwd":"'$PROJ'","tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"stdout":"ok","stderr":"","exitCode":0}}' "$LOG"
check "successful Bash ok=true"        'jq -e "select(.event==\"tool\" and .summary==\"npm test\" and .ok==true)" "$(logfile)" >/dev/null'

send '{"hook_event_name":"PostToolUse","session_id":"'$SID'","cwd":"'$PROJ'","tool_name":"Bash","tool_input":{"command":"npm run lint"},"tool_response":{"stdout":"","stderr":"2 errors","exitCode":1}}' "$LOG"
check "failed Bash ok=false"           'jq -e "select(.event==\"tool\" and .summary==\"npm run lint\" and .ok==false)" "$(logfile)" >/dev/null'

send '{"hook_event_name":"PostToolUse","session_id":"'$SID'","cwd":"'$PROJ'","tool_name":"Edit","tool_input":{"file_path":"/p/routes/api.php"},"tool_response":{"success":true}}' "$LOG"
check "Edit logs file path"            'jq -e "select(.tool==\"Edit\" and .summary==\"/p/routes/api.php\")" "$(logfile)" >/dev/null'

send '{"hook_event_name":"PostToolUse","session_id":"'$SID'","cwd":"'$PROJ'","tool_name":"Bash","tool_input":{"command":"curl -H \"Authorization: Bearer abc.def.ghi\" x"},"tool_response":{"stdout":"api_key=sk-live1234567890abcdef","exitCode":0}}' "$LOG"
check "redacts bearer token"           '! grep -q "abc.def.ghi" "$(logfile)"'
check "redacts api key in output"      '! grep -q "1234567890abcdef" "$(logfile)"'

big=$(head -c 10000 /dev/zero | tr '\0' 'x')
send '{"hook_event_name":"PostToolUse","session_id":"'$SID'","cwd":"'$PROJ'","tool_name":"Read","tool_input":{"file_path":"/big"},"tool_response":"'$big'"}' "$LOG"
check "caps output at 2000 chars"      '[ "$(jq -r "select(.summary==\"/big\") | .output | length" "$(logfile)")" -le 2000 ]'

send 'not json' "$LOG"; check "bad input never fails"  '[ $? -eq 0 ]'
check "every line is valid JSON"       'jq -c . "$(logfile)" >/dev/null'

echo "redaction rules (each tested alone)"
. "$ROOT/scripts/lib.sh"
r() { printf '%s' "$1" | ao_redact 2000; }
SK="sk""-abcdefghijklmnopqrstuvwx"; GHT="gh""p_ABCDEFGHIJKLMNOPQRST"; AK="AK""IAABCDEFGHIJKLMNOP"; XB="xo""xb-1234-abcd-efgh"
check "sk- key redacted"          '! grep -q "ijklmnop" <<<"$(r "result $SK done")"'
check "github token redacted"     '! grep -q "KLMNOPQRST" <<<"$(r "using $GHT now")"'
check "aws key redacted"          '! grep -q "EFGHIJKLMNOP" <<<"$(r "id $AK x")"'
check "slack token redacted"      '! grep -q "abcd-efgh" <<<"$(r "hook $XB x")"'
check "password=value redacted"   '! grep -q "hunter2" <<<"$(r "password=hunter2 next")"'
check "bearer redacted"           '! grep -q "abc.def.ghi" <<<"$(r "Bearer abc.def.ghi")"'
check "plain text untouched"      '[ "$(r "npm test passed")" = "npm test passed" ]'
check "length capped"             '[ "$(r "$(printf "x%.0s" {1..3000})" | wc -c | tr -d " ")" -le 2000 ]'

echo "done-gate"
send '{"hook_event_name":"UserPromptSubmit","session_id":"'$SID'","cwd":"'$PROJ'","prompt":"next turn"}' "$LOG"
out=$(send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false}' "$GATE")
check "no GOAL.md → allows stop"       '[ -z "$out" ]'

cat > "$PROJ/.agent-log/GOAL.md" <<'EOF'
---
status: active
---
# Goal
> "add a health endpoint"
## Acceptance criteria
- [x] C1: route exists · check: routes/api.php
- [ ] C2: GET /health returns 200 · check: `curl localhost/health`
- [ ] C3: docs updated · check: README.md — BLOCKED: no README in repo
EOF
out=$(send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false}' "$GATE")
check "active goal with open C2 → blocks"     '[ "$(jq -r .decision <<<"$out")" = "block" ]'
check "block reason names C2 only"           'jq -r .reason <<<"$out" | grep -q "criteria: C2\."'
check "gate_block logged"                    'jq -e "select(.event==\"gate_block\")" "$(logfile)" >/dev/null'

out=$(send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":true}' "$GATE")
check "second attempt → releases (no loop)"  '[ -z "$out" ]'
check "gate_released logged"                 'jq -e "select(.event==\"gate_released\")" "$(logfile)" >/dev/null'

send '{"hook_event_name":"UserPromptSubmit","session_id":"'$SID'","cwd":"'$PROJ'","prompt":"next turn"}' "$LOG"
sed -i.bak 's/^status: active/status: partial/' "$PROJ/.agent-log/GOAL.md"
out=$(send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false}' "$GATE")
check "status partial → allows stop"         '[ -z "$out" ]'

sed -i.bak 's/^status: partial/status: active/' "$PROJ/.agent-log/GOAL.md"
out=$(AGENT_OPS_GATE=off send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false}' "$GATE")
check "AGENT_OPS_GATE=off disables gate"     '[ -z "$out" ]'

printf -- '---\nstatus: active\n---\n- [x] C1: done · check: x\n- [ ] C2: b · check: y — BLOCKED: waiting on vendor\n' > "$PROJ/.agent-log/GOAL.md"
send '{"hook_event_name":"UserPromptSubmit","session_id":"'$SID'","cwd":"'$PROJ'","prompt":"t"}' "$LOG"
out=$(send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false}' "$GATE")
check "active goal, all ticked/BLOCKED → allows" '[ -z "$out" ]'

echo "done-gate rule 2 (edits without a goal)"
rm -f "$PROJ/.agent-log/GOAL.md"
send '{"hook_event_name":"UserPromptSubmit","session_id":"'$SID'","cwd":"'$PROJ'","prompt":"rename a var"}' "$LOG"
send '{"hook_event_name":"PostToolUse","session_id":"'$SID'","cwd":"'$PROJ'","tool_name":"Edit","tool_input":{"file_path":"/p/app.js"},"tool_response":{"success":true}}' "$LOG"
out=$(send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false}' "$GATE")
check "edit with no goal → blocks"           'jq -r .reason <<<"$out" | grep -q "without a goal contract"'
send '{"hook_event_name":"PostToolUse","session_id":"'$SID'","cwd":"'$PROJ'","tool_name":"Bash","tool_input":{"command":"mv .agent-log/GOAL.md .agent-log/goals/2026-11-05-x.md"},"tool_response":{"exitCode":0}}' "$LOG"
out=$(send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false}' "$GATE")
check "goal archived this turn → allows"     '[ -z "$out" ]'
send '{"hook_event_name":"UserPromptSubmit","session_id":"'$SID'","cwd":"'$PROJ'","prompt":"what does app.js do?"}' "$LOG"
send '{"hook_event_name":"PostToolUse","session_id":"'$SID'","cwd":"'$PROJ'","tool_name":"Read","tool_input":{"file_path":"/p/app.js"},"tool_response":"x"}' "$LOG"
out=$(send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false}' "$GATE")
check "read-only turn → allows"              '[ -z "$out" ]'

echo "goal-nudge"
NUDGE="$ROOT/scripts/goal-nudge.sh"
out=$(send '{"hook_event_name":"UserPromptSubmit","session_id":"'$SID'","cwd":"'$PROJ'","prompt":"x"}' "$NUDGE")
check "no goal → tells agent to write GOAL.md" 'jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "goal-contract"'
printf -- '---\nstatus: active\n---\n- [ ] C1: a · check: x\n' > "$PROJ/.agent-log/GOAL.md"
out=$(send '{"hook_event_name":"UserPromptSubmit","session_id":"'$SID'","cwd":"'$PROJ'","prompt":"x"}' "$NUDGE")
check "active goal → lists open criteria"      'jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "open criteria: C1"'
printf -- '---\nstatus: active\n---\n- [ ] C1: a · check: x\n' > "$PROJ/.agent-log/GOAL.md"

echo "claims"
send '{"hook_event_name":"Stop","session_id":"'$SID'","cwd":"'$PROJ'","stop_hook_active":false,"last_assistant_message":"Done! All tests pass."}' "$LOG"
check "stop logs claim + goal status"        'jq -e "select(.event==\"stop\" and .claim==\"Done! All tests pass.\" and .goal_status==\"active\" and .goal_open_criteria==1)" "$(logfile)" >/dev/null'

echo "report"
rep=$(bash "$REPORT" "$(logfile)")
check "report lists failed lint"             'grep -q "npm run lint" <<<"$rep"'
check "report flags tests claimed after edit" 'grep -q "no test command ran after the last edit" <<<"$rep"'
check "report flags done vs goal status"     'grep -q "Claims done, but goal status is active" <<<"$rep"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
