#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit) hook: scan the text just written for debug leftovers,
# secrets, local paths and untracked TODOs. Never blocks — tells the agent what to fix.
set -u
trap 'exit 0' ERR
exec 2>/dev/null
command -v jq >/dev/null 2>&1 || exit 0
[ "${CODE_STANDARDS_SCAN:-on}" = "off" ] && exit 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

input="$(cat)"
fpath=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$fpath" ] || exit 0
case "$fpath" in *.md|*.txt|*.lock|*.json|*.yml|*.yaml|*/.agent-log/*) exit 0 ;; esac
text=$(jq -r '[.tool_input.new_string // empty, .tool_input.content // empty, (.tool_input.edits // [] | map(.new_string) | join("\n"))] | map(select(. != "")) | join("\n")' <<<"$input")
[ -n "$text" ] || exit 0

hits=$(printf '%s\n' "$text" | bash "$HERE/leftover-scan.sh" --stdin "$fpath" | head -8)
[ -n "$hits" ] || exit 0
msg="code-standards: the code you just wrote to $(basename "$fpath") has leftovers to fix before committing (line numbers are within the edited text):
$hits
Remove debug output, move secrets to config/env, use relative paths, and give TODOs a task/issue ID (TODO(T7): …)."
jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$m}}'
exit 0
