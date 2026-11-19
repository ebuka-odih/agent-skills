#!/usr/bin/env bash
# Edit docs/plan/PLAN.md without breaking its grammar, so requests land in the plan instead of in chat.
#
#   plan.sh add "<title>" --covers R5[,R6|setup|fix] [--depends T3,T4] [--size S|M] [--milestone M4]
#                                   new task at the end of the milestone (default: the active one); prints its ID
#   plan.sh mark T7 <x|~|!|-|todo> ["note"]   change a task's mark ("!" needs a note: what blocks it)
#   plan.sh released M4 v0.12.0     milestone → released, "released:" line, progress-log line; lists blocked tasks to re-check
#   plan.sh log "<text>"            append "- <date> · <text>" to ## Progress log
#   plan.sh release-policy          per-feature | per-milestone | manual (PLAN.md front matter "release:", default per-milestone)
# Options: --file <PLAN.md> (default docs/plan/PLAN.md). Exit 2 on usage errors, 1 when the plan doesn't allow it.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=parse.sh
. "$HERE/parse.sh"

cmd="${1:-}"; shift || true
PLAN="docs/plan/PLAN.md"; covers=""; depends="-"; size="S"; ms=""; args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --file) PLAN="$2"; shift ;;
    --covers) covers="$2"; shift ;;
    --depends) depends="$2"; shift ;;
    --size) size="$2"; shift ;;
    --milestone) ms="$2"; shift ;;
    *) args+=("$1") ;;
  esac
  shift
done
die() { echo "plan.sh: $1" >&2; exit "${2:-2}"; }
today() { date +%Y-%m-%d; }
[ "$cmd" = "" ] || [ "$cmd" = -h ] && { sed -n '2,11p' "$0"; exit 2; }
[ -f "$PLAN" ] || die "no $PLAN — run the project-plan skill first" 1

rewrite() { # awk program + vars → replace PLAN in place (keeps mode)
  local tmp; tmp="$(mktemp "${PLAN}.XXXX")" || die "cannot write $PLAN" 1
  awk "$@" "$PLAN" > "$tmp" && cat "$tmp" > "$PLAN"; rm -f "$tmp"
}
append_log() { # text
  if grep -q '^## Progress log' "$PLAN"; then
    rewrite -v line="- $(today) · $1" '
      { lines[NR] = $0 } /^## Progress log/ { p = NR } /^## / && p && NR > p && !e { e = NR }
      END { last = e ? e - 1 : NR; while (last > p && lines[last] ~ /^[[:space:]]*$/) last--
            for (i = 1; i <= NR; i++) { print lines[i]; if (i == last) print line } }'
  else printf '\n## Progress log\n- %s · %s\n' "$(today)" "$1" >> "$PLAN"; fi
}
set_updated() { rewrite -v d="$(today)" 'NR <= 10 && /^updated:/ && !u { $0 = "updated: " d; u = 1 } { print }'; }

case "$cmd" in
  add)
    title="${args[0]:-}"; [ -n "$title" ] || die 'usage: plan.sh add "<title>" --covers R5'
    [ -n "$covers" ] || die "every task covers something: --covers R5 | NFR2 | setup | fix"
    case "$title" in *" · "*|*" — "*) die "the title can't contain ' · ' or ' — ' (they separate fields)" ;; esac
    case "$size" in S|M) ;; *) die "size is S or M; an L task is two tasks" ;; esac
    [ -n "$ms" ] || ms="$(plan_milestones "$PLAN" | awk -F'\t' '$3=="active"{print $1; exit}')"
    [ -n "$ms" ] || die "no active milestone — pass --milestone M<n>" 1
    plan_milestones "$PLAN" | cut -f1 | grep -qx "$ms" || die "no milestone $ms in $PLAN" 1
    n=$(grep -oE '^[[:space:]]*- \[.\] T[0-9]+' "$PLAN" | grep -oE '[0-9]+$' | sort -n | tail -1)
    id="T$(( ${n:-0} + 1 ))"
    line="- [ ] $id · $title · covers: $covers · depends: $depends · size: $size"
    rewrite -v ms="$ms" -v line="$line" '
      { lines[NR] = $0 }
      /^## M[0-9]+/ { match($0, /M[0-9]+/); cur = substr($0, RSTART, RLENGTH); if (cur == ms) { s = NR } else if (s && !e) e = NR; next }
      /^## / && s && !e { e = NR }
      s && !e && /^[[:space:]]*- \[.\] T[0-9]+/ { lt = NR }
      END { if (!e) e = NR + 1
            at = lt; if (!at) { at = e - 1; while (at > s && lines[at] ~ /^[[:space:]]*$/) at-- }
            for (i = 1; i <= NR; i++) { print lines[i]; if (i == at) { if (!lt) print ""; print line } } }'
    set_updated
    echo "$id" ;;
  mark)
    id="${args[0]:-}"; m="${args[1]:-}"; note="${args[2]:-}"
    [ -n "$id" ] && [ -n "$m" ] || die "usage: plan.sh mark T7 <x|~|!|-|todo> [note]"
    [ "$m" = todo ] && m=" "
    case "$m" in x|"~"|"!"|-|" ") ;; *) die "mark is one of: x ~ ! - todo" ;; esac
    [ "$m" = "!" ] && [ -z "$note" ] && die "a blocked task needs a note: what blocks it"
    grep -qE "^[[:space:]]*- \[.\] $id · " "$PLAN" || die "no task $id in $PLAN" 1
    rewrite -v id="$id" -v m="$m" -v note="$note" '
      $0 ~ "^[[:space:]]*- \\[.\\] " id " · " {
        sub(/\[.\]/, "[" m "]")
        if (m != "!" && m != "-") sub(/ — .*$/, "")           # a blocker note goes when the block does
        if (note != "") { sub(/ — .*$/, ""); $0 = $0 " — " note } }
      { print }'
    set_updated
    grep -E "^[[:space:]]*- \[.\] $id · " "$PLAN" ;;
  released)
    ms="${args[0]:-}"; ver="${args[1]:-}"
    [ -n "$ms" ] && [ -n "$ver" ] || die "usage: plan.sh released M4 v0.12.0"
    plan_milestones "$PLAN" | cut -f1 | grep -qx "$ms" || die "no milestone $ms in $PLAN" 1
    open=$(plan_tasks "$PLAN" | awk -F'\t' -v ms="$ms" '$1==ms && ($2==" " || $2=="~") {printf "%s ", $3}')
    [ -z "$open" ] || die "$ms still has open tasks: ${open}— finish, move or drop them first" 1
    rewrite -v ms="$ms" -v ver="$ver" -v d="$(today)" '
      /^## M[0-9]+/ { match($0, /M[0-9]+/); in_ms = (substr($0, RSTART, RLENGTH) == ms)
        if (in_ms) { sub(/status:[[:space:]]*[a-z]+/, "status: released"); if ($0 !~ /status:/) $0 = $0 " · status: released" }
        print; next }
      /^## / { in_ms = 0 }
      in_ms && /^released:/ { next }
      in_ms && /^demo:/ { print; print "released: " ver " · " d; next }
      { print }'
    append_log "$ms released as $ver"
    set_updated
    echo "$ms released as $ver"
    blocked=$(plan_tasks "$PLAN" | awk -F'\t' '$2=="!" {printf "  %s · %s — %s\n", $3, $4, $7}')
    [ -n "$blocked" ] && printf 'Blocked tasks — is the blocker gone after this release? (plan.sh mark <T> x|todo)\n%s\n' "$blocked"
    exit 0 ;;
  log)
    [ -n "${args[0]:-}" ] || die 'usage: plan.sh log "<text>"'
    append_log "${args[*]}"; echo "logged" ;;
  release-policy)
    p=$(awk 'NR==1 && /^---/ {fm=1; next} fm && /^---/ {exit} fm && /^release:/ { sub(/^release:[[:space:]]*/, ""); sub(/[[:space:]#].*/, ""); print; exit }' "$PLAN")
    echo "${p:-per-milestone}" ;;
  *) sed -n '2,11p' "$0"; exit 2 ;;
esac
