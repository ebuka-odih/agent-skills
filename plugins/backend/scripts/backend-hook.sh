#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit) hook: after a migration, job, scheduler or Python/PHP file is written,
# run the backend rules on the file and tell the agent what's risky. Never blocks.
set -u
trap 'exit 0' ERR
exec 2>/dev/null
command -v jq >/dev/null 2>&1 || exit 0
[ "${BACKEND_CHECK:-on}" = "off" ] && exit 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=backend-patterns.sh
. "$HERE/backend-patterns.sh"

input="$(cat)"
fpath=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$fpath" ] || exit 0
case "$(be_kind "$fpath")" in migration|laravel-job|python|php) ;; *) exit 0 ;; esac
# the tool already wrote the file: scan it on disk (whole-file rules like "job without $tries" need all of it)
src="$fpath"
if [ ! -f "$src" ]; then
  src="$(mktemp)"; trap 'rm -f "$src"' EXIT
  jq -r '.tool_input.content // .tool_input.new_string // empty' <<<"$input" > "$src"
fi
hits=$(be_scan_file "$fpath" "$src" | grep -E '^(error|warn) ' | head -8)
[ -n "$hits" ] || exit 0
msg="backend: $(basename "$fpath") has production risks:
$hits
See the backend plugin: migrations (expand → migrate → contract), background-jobs (job contract), integrations (timeouts). Fix them, or say in the PR why a warning doesn't apply (e.g. a small table)."
jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$m}}'
exit 0
