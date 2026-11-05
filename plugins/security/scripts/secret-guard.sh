#!/usr/bin/env bash
# PreToolUse(Write|Edit|MultiEdit) hook: deny writing a real-looking secret into a file
# that git would track. Allowed: gitignored .env files. Placeholders are fine everywhere.
set -u
trap 'exit 0' ERR
exec 2>/dev/null
command -v jq >/dev/null 2>&1 || exit 0
[ "${SECRET_GUARD:-on}" = "off" ] && exit 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=patterns.sh
. "$HERE/patterns.sh"

input="$(cat)"
path=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$path" ] || exit 0
text=$(jq -r '[.tool_input.content // empty, .tool_input.new_string // empty, (.tool_input.edits // [] | map(.new_string) | join("\n"))] | map(select(. != "")) | join("\n")' <<<"$input")
[ -n "$text" ] || exit 0

kinds=$(printf '%s' "$text" | secret_kinds | paste -sd, -)
[ -n "$kinds" ] || exit 0

deny() {
  jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'
  exit 0
}

base=$(basename "$path"); dir=$(dirname "$path")
case "$base" in
  .env.example|.env.sample|.env.dist|.env.template)
    deny "security: $base is committed and must only hold placeholders, but this write contains a real-looking secret ($kinds). Put the name with an empty value here, and the real value in .env." ;;
  .env|.env.*|*.env)
    if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git -C "$dir" check-ignore -q "$path" && exit 0
      deny "security: $base isn't gitignored, so this secret ($kinds) would be committed. Add '$base' to .gitignore first, then write it."
    fi
    exit 0 ;;
esac
deny "security: this write puts a real-looking secret ($kinds) into $base. Secrets go in a gitignored .env file (local) or the platform secret store, and code reads them through config (Laravel config/services.php → env(), FastAPI Settings, never frontend code). If this is a test fixture, use an obviously fake value (e.g. sk_test_..., EXAMPLE)."
