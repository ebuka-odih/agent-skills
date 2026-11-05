#!/usr/bin/env bash
# PreToolUse(Bash) hook: guard dangerous or sloppy git commands.
#   deny  · force-push (any --force/-f without lease; any force to main/master)
#   deny  · git commit/push with --no-verify
#   deny  · commit subject that isn't a Conventional Commit
#   ask   · git commit while on main/master (skip with `git config collab.allowMainCommits true`)
# Anything it can't parse is allowed. Never blocks non-git commands.
set -u
trap 'exit 0' ERR
exec 2>/dev/null
command -v jq >/dev/null 2>&1 || exit 0
[ "${COLLAB_GUARD:-on}" = "off" ] && exit 0

input="$(cat)"
[ "$(jq -r '.tool_name // empty' <<<"$input")" = "Bash" ] || exit 0
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$cmd" ] || exit 0
grep -qE '(^|[;&|(]|\s)git\s' <<<"$cmd" || exit 0

decide() { # decision reason
  jq -nc --arg d "$1" --arg r "$2" '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:$d, permissionDecisionReason:$r}}'
  exit 0
}
branch() { git -C "${cwd:-.}" branch --show-current 2>/dev/null; }
SUBJECT_RE='^(feat|fix|perf|refactor|test|docs|build|ci|chore|revert|style)(\([a-z0-9._/-]+\))?!?: .{1,72}$'

# --no-verify on commit/push
if grep -qE 'git\s+(commit|push)\b[^;&|]*--no-verify' <<<"$cmd"; then
  decide deny "collaboration: --no-verify skips the project's checks. Fix what the hook reports instead of bypassing it."
fi

# Force push
if grep -qE 'git\s+push\b' <<<"$cmd"; then
  push=$(grep -oE 'git\s+push\b[^;&|]*' <<<"$cmd" | head -1)
  forced=0; lease=0
  grep -qE '(\s--force(\s|$)|\s-f(\s|$)|\s-[a-zA-Z]*f[a-zA-Z]*(\s|$)|\s\+[^ ]+)' <<<"$push" && forced=1
  grep -qE -- '--force-with-lease|--force-if-includes' <<<"$push" && lease=1
  if [ $forced = 1 ] || [ $lease = 1 ]; then
    target_main=0
    grep -qE '(\s|:|\+)(main|master)(\s|$)' <<<"$push" && target_main=1
    if ! grep -qE 'git\s+push\s+\S+\s+\S' <<<"$push"; then   # no refspec → current branch
      case "$(branch)" in main|master) target_main=1 ;; esac
    fi
    [ $target_main = 1 ] && decide deny "collaboration: force-pushing main/master rewrites shared history. Push a branch and open a PR instead."
    [ $forced = 1 ] && [ $lease = 0 ] && decide deny "collaboration: use --force-with-lease instead of --force so you can't overwrite someone else's pushes."
  fi
fi

# Commit
if grep -qE 'git\s+commit\b' <<<"$cmd"; then
  commit=$(awk 'BEGIN{RS="\0"} {i=index($0,"git commit"); if(i==0){match($0,/git[ \t]+commit/); i=RSTART} print substr($0,i)}' <<<"$cmd")
  subject=""
  if grep -qE "<<-?\s*['\"]?[A-Z_]+['\"]?" <<<"$commit"; then
    # heredoc: first non-empty line after the line holding the marker
    subject=$(awk 'f && NF {print; exit} /<<-?[ \t]*['"'"'"]?[A-Z_]+/ {f=1}' <<<"$commit")
  elif grep -qE '(\s-m|\s--message)(\s|=)' <<<"$commit"; then
    subject=$(head -1 <<<"$commit" | sed -nE 's/.*(-m|--message)[ =]+"([^"]*)".*/\2/p')
    [ -n "$subject" ] || subject=$(head -1 <<<"$commit" | sed -nE "s/.*(-m|--message)[ =]+'([^']*)'.*/\2/p")
  fi
  subject=$(printf '%s' "$subject" | head -1 | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  if [ -n "$subject" ] && ! grep -qE '^(Merge |Revert ")' <<<"$subject"; then
    grep -qE "$SUBJECT_RE" <<<"$subject" || decide deny "collaboration: commit subject \"$subject\" isn't a Conventional Commit. Use 'type(scope): summary' (≤72 chars, imperative), e.g. 'fix(auth): reject expired refresh tokens'. Types: feat fix perf refactor test docs build ci chore revert."
  fi
  # Branch named for a plan task → the message must reference it (Refs: T7, R7)
  task=$(branch | grep -oE 'T[0-9]+' | head -1)
  if [ -n "$task" ] && [ -n "$subject" ] && ! grep -qE "\b$task\b" <<<"$commit"; then
    decide deny "collaboration: this branch is for plan task $task but the commit message doesn't mention it. Add a footer like 'Refs: $task, R<n>' (requirement IDs from the task's covers: in docs/plan/PLAN.md)."
  fi
  case "$(branch)" in
    main|master)
      [ "$(git -C "${cwd:-.}" config --bool collab.allowMainCommits 2>/dev/null)" = "true" ] || \
        decide ask "collaboration: you're committing directly to $(branch). The team default is a branch per task (git switch -c <type>/<task>-<slug>). Allow this commit on $(branch)? (Solo repos: git config collab.allowMainCommits true)"
      ;;
  esac
fi
exit 0
