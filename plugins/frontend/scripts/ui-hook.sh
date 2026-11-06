#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit) hook: flag raw palette colours, colour literals, arbitrary
# values and inline styles in newly written frontend code. Never blocks — tells the agent the token to use.
set -u
trap 'exit 0' ERR
exec 2>/dev/null
command -v jq >/dev/null 2>&1 || exit 0
[ "${UI_TOKEN_CHECK:-on}" = "off" ] && exit 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ui-patterns.sh
. "$HERE/ui-patterns.sh"

input="$(cat)"
fpath=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$fpath" ] || exit 0
text=$(jq -r '[.tool_input.new_string // empty, .tool_input.content // empty, (.tool_input.edits // [] | map(.new_string) | join("\n"))] | map(select(. != "")) | join("\n")' <<<"$input")
[ -n "$text" ] || exit 0

hits=$(printf '%s\n' "$text" | awk '{print NR "\t" $0}' | ui_scan_text "$fpath" | head -8)
[ -n "$hits" ] || exit 0
msg="frontend: $(basename "$fpath") has UI values that bypass the design tokens (line numbers are within the edited text):
$hits
Use semantic tokens (bg-primary, text-muted-foreground, border-border, bg-destructive, or a status token like bg-warning), the spacing/type scale instead of arbitrary [values], and cva variants instead of inline styles. New colours go in globals.css (:root, .dark, @theme inline). Documented exceptions belong in docs/ui/UI.md."
jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$m}}'
exit 0
