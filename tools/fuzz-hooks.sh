#!/usr/bin/env bash
# Property/fuzz test for every hook script in the marketplace.
# For N seeded random inputs (valid hook JSON with hostile values, wrong shapes, invalid JSON),
# every hook must: exit 0 · print nothing or valid JSON · use a known decision · finish < 3 s.
# Usage: tools/fuzz-hooks.sh [N=150] [seed=42]
# Key-shaped fuzz values are assembled at runtime so this file never contains one (the secret guard checks).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
N="${1:-150}"; RANDOM="${2:-42}"
HOOKS=(
  "agent-ops/scripts/log-event.sh" "agent-ops/scripts/goal-nudge.sh" "agent-ops/scripts/done-gate.sh"
  "collaboration/scripts/git-guard.sh" "code-standards/scripts/leftover-hook.sh" "security/scripts/secret-guard.sh"
  "devops/scripts/infra-guard.sh" "product/scripts/plan-context.sh" "ai-engineering/scripts/ai-context.sh"
)
PROJ="$(mktemp -d)"; trap 'rm -rf "$PROJ"' EXIT
export CLAUDE_PROJECT_DIR="$PROJ"
mkdir -p "$PROJ/.agent-log" "$PROJ/docs/plan" "$PROJ/docs/spec"
printf -- '---\nstatus: active\n---\n- [ ] C1: x · check: y\n' > "$PROJ/.agent-log/GOAL.md"

PEM="-----BEGIN ""RSA PRIVATE KEY-----"
AKEY="AK""IA""QWERTYUIOPASDFGH"
PIECES=( 'git push --force origin main' 'git commit -m "wip"' "terraform destroy" 'rm -rf /' '$(whoami)' '`id`' '"; DROP TABLE x; --'
         '日本語テキスト' '🔥🔥' $'line1\nline2' '\\\\' "'single'" '{"nested":{"json":true}}' "$PEM" "$AKEY"
         'php artisan migrate:fresh' 'console.log(x)' 'dd($a)' '/Users/someone/x' 'TODO later' '' ' ' '%s%n%x' '../../etc/passwd' )
EVENTS=( PreToolUse PostToolUse UserPromptSubmit Stop SessionStart SubagentStop SessionEnd Unknown )
TOOLS=( Bash Write Edit MultiEdit Read Skill mcp__x__y "" )

rand_piece() { echo "${PIECES[$((RANDOM % ${#PIECES[@]}))]}"; }
rand_str() { local s="" i; for i in $(seq 1 $((RANDOM % 4 + 1))); do s="$s $(rand_piece)"; done; [ $((RANDOM % 15)) = 0 ] && s="$s$(head -c $((RANDOM % 6000 + 1000)) /dev/zero | tr '\0' 'a')"; printf '%s' "$s"; }

make_input() {
  case $((RANDOM % 10)) in
    0) printf 'not json %s' "$(rand_piece)" ;;                       # invalid JSON
    1) printf '[]' ;;                                                  # wrong shape
    2) printf '{"tool_input":"string not object"}' ;;
    *) jq -nc --arg e "${EVENTS[$((RANDOM % ${#EVENTS[@]}))]}" --arg t "${TOOLS[$((RANDOM % ${#TOOLS[@]}))]}" \
          --arg c "$(rand_str)" --arg p "$PROJ/$(rand_piece | tr -cd 'a-z/._-' | head -c 40)x.py" --arg s "$(rand_str)" \
          --arg cwd "$PROJ" --argjson a "$([ $((RANDOM % 2)) = 0 ] && echo true || echo false)" \
          '{hook_event_name:$e, session_id:"fuzz-session", cwd:$cwd, tool_name:$t,
            tool_input:{command:$c, file_path:$p, content:$s, new_string:$s, old_string:"x"},
            tool_response:{stdout:$s, exitCode:1}, prompt:$c, stop_hook_active:$a, last_assistant_message:$s}' ;;
  esac
}

fail=0; runs=0
for i in $(seq 1 "$N"); do
  input="$(make_input)"
  for h in "${HOOKS[@]}"; do
    runs=$((runs+1))
    start=$(date +%s)
    out=$(printf '%s' "$input" | bash "$ROOT/plugins/$h" 2>/dev/null); rc=$?
    dur=$(( $(date +%s) - start ))
    problem=""
    [ "$rc" = 0 ] || problem="exit $rc"
    if [ -z "$problem" ] && [ -n "$out" ]; then
      if ! jq -e . >/dev/null 2>&1 <<<"$out"; then problem="invalid JSON output"
      else
        d=$(jq -r '.hookSpecificOutput.permissionDecision // .decision // "none"' <<<"$out")
        case "$d" in allow|deny|ask|block|none) ;; *) problem="unknown decision '$d'" ;; esac
      fi
    fi
    [ -z "$problem" ] && [ "$dur" -ge 3 ] && problem="slow (${dur}s)"
    if [ -n "$problem" ]; then
      fail=$((fail+1))
      echo "✘ $h · $problem · input: $(printf '%s' "$input" | head -c 200)"
    fi
  done
done
echo "fuzz: $runs hook runs ($N inputs × ${#HOOKS[@]} hooks), $fail property violations"
[ "$fail" -eq 0 ]
