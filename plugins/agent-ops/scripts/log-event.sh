#!/usr/bin/env bash
# Appends one JSON line per hook event to <project>/.agent-log/sessions/<date>_<session>.jsonl
# Never blocks the agent: any failure exits 0 silently.
set -uo pipefail
trap 'exit 0' ERR
exec 2>/dev/null  # hooks must never print noise into the session

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
[ -n "$input" ] || exit 0

event=$(jq -r '.hook_event_name // empty' <<<"$input")
sid=$(jq -r '.session_id // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

logdir="$(ao_log_dir "$cwd")"
file="$(ao_session_file "$logdir" "$sid")"
ts="$(ao_now)"

base=$(jq -nc --arg ts "$ts" --arg sid "$sid" '{ts:$ts, session:$sid}')

# One-line human summary of a tool call's input.
tool_summary() {
  jq -r '
    .tool_input as $i |
    if   .tool_name == "Bash"  then ($i.command // "")
    elif (.tool_name == "Edit" or .tool_name == "Write" or .tool_name == "Read" or .tool_name == "NotebookEdit")
                                   then ($i.file_path // $i.notebook_path // "")
    elif .tool_name == "Grep"  then "\($i.pattern // "") in \($i.path // ".")"
    elif .tool_name == "Glob"  then ($i.pattern // "")
    elif .tool_name == "WebFetch" then ($i.url // "")
    elif .tool_name == "WebSearch" then ($i.query // "")
    elif .tool_name == "Agent" or .tool_name == "Task" then ($i.description // "")
    elif .tool_name == "Skill" then ($i.skill // "")
    else ($i | tostring)
    end' <<<"$input" | tr '\n' ' ' | sed -E 's/[[:space:]]+$//' | ao_redact 500
}

case "$event" in
  SessionStart)
    branch=$(git -C "$(ao_project_dir "$cwd")" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    commit=$(git -C "$(ao_project_dir "$cwd")" rev-parse --short HEAD 2>/dev/null || echo "")
    source=$(jq -r '.source // ""' <<<"$input")
    line=$(jq -c --arg cwd "$cwd" --arg b "$branch" --arg c "$commit" --arg s "$source" \
      '. + {event:"session_start", cwd:$cwd, git_branch:$b, git_commit:$c, source:$s}' <<<"$base")
    ;;

  UserPromptSubmit)
    prompt=$(jq -r '.prompt // ""' <<<"$input" | ao_redact 8000)
    line=$(jq -c --arg p "$prompt" '. + {event:"prompt", prompt:$p}' <<<"$base")
    ;;

  PostToolUse|PostToolUseFailure)
    tool=$(jq -r '.tool_name // ""' <<<"$input")
    summary=$(tool_summary)
    # Success heuristic: explicit failure event, is_error / success fields, or a non-zero exit code.
    ok=$(jq -r --arg ev "$event" '
      if $ev == "PostToolUseFailure" then false
      else (.tool_response // {}) as $r |
        if ($r|type) == "object" then
          if ($r.is_error == true) or ($r.success == false) or ($r.interrupted == true) then false
          elif (($r.exitCode // $r.exit_code // 0) | tonumber? // 0) != 0 then false
          else true end
        else true end
      end' <<<"$input")
    out=$(jq -r '
      (.tool_response // .error // "") |
      if type == "object" then ((.stdout // "") + (if (.stderr // "") != "" then "\n[stderr] " + .stderr else "" end) + (.error // "") )
      else tostring end' <<<"$input" | ao_redact 2000)
    line=$(jq -c --arg t "$tool" --arg s "$summary" --argjson ok "$ok" --arg o "$out" \
      '. + {event:"tool", tool:$t, summary:$s, ok:$ok, output:$o}' <<<"$base")
    ;;

  SubagentStop)
    line=$(jq -c '. + {event:"subagent_stop"}' <<<"$base")
    ;;

  Stop)
    # The agent's final message is its claim. Prefer the field if present, else read the transcript.
    claim=$(jq -r '.last_assistant_message // empty' <<<"$input")
    tpath=$(jq -r '.transcript_path // empty' <<<"$input")
    if [ -z "$claim" ] && [ -n "$tpath" ] && [ -f "$tpath" ]; then
      claim=$(tail -n 200 "$tpath" | jq -rs '
        [ .[] | select(.type=="assistant") | .message.content
          | if type=="array" then (map(select(.type=="text") | .text) | join("\n")) else tostring end
          | select(length > 0) ] | last // ""' 2>/dev/null || echo "")
    fi
    claim=$(printf '%s' "$claim" | ao_redact 4000)
    gstatus=$(ao_goal_status "$logdir")
    gopen=$(ao_goal_open "$logdir")
    line=$(jq -c --arg c "$claim" --arg g "$gstatus" --argjson n "${gopen:-0}" \
      '. + {event:"stop", claim:$c, goal_status:$g, goal_open_criteria:$n}' <<<"$base")
    ;;

  SessionEnd)
    reason=$(jq -r '.reason // ""' <<<"$input")
    line=$(jq -c --arg r "$reason" '. + {event:"session_end", reason:$r}' <<<"$base")
    ;;

  *)
    line=$(jq -c --arg e "$event" '. + {event:$e}' <<<"$base")
    ;;
esac

printf '%s\n' "$line" >> "$file"
exit 0
