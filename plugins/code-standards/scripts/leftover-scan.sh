#!/usr/bin/env bash
# Find debug leftovers, secrets, local paths and untracked TODOs in NEW code only.
# Usage:
#   leftover-scan.sh                      # added lines in the working tree vs HEAD (+ untracked files)
#   leftover-scan.sh --stdin <path>       # scan text on stdin as if it were <path> (used by the hook)
# Output: one line per hit "path:line: kind: text". Exit 0 always.
set -u

scan_text() { # path, reads text on stdin with "lineno<TAB>text" lines
  local fpath="$1" ext="${1##*.}" base; base=$(basename "$1")
  local is_test=0; grep -qiE '(^|/)(tests?|__tests__|spec)/|(_test|\.test|\.spec|Test)\.[a-z]+$' <<<"$fpath" && is_test=1
  local debug=""
  case "$ext" in
    php) debug='(^|[^>:$a-zA-Z_])(dd|dump|var_dump|print_r|ray)\(' ;;
    py)  debug='^[[:space:]]*print\(|breakpoint\(\)|pdb\.set_trace\(|^[[:space:]]*import i?pdb' ;;
    js|jsx|ts|tsx|mjs|cjs|vue|svelte) debug='console\.(log|debug|trace)\(|(^|[^a-zA-Z_])debugger;?[[:space:]]*$' ;;
  esac
  # Regex goes through ENVIRON: awk -v would eat the backslashes in \(.
  LS_PATH="$fpath" LS_DEBUG="$debug" LS_TEST="$is_test" awk -F'\t' '
    BEGIN { path=ENVIRON["LS_PATH"]; debug=ENVIRON["LS_DEBUG"]; is_test=ENVIRON["LS_TEST"]+0 }
    {
      n=$1; t=substr($0, index($0, "\t")+1)
      if (debug != "" && t ~ debug && !(is_test && t ~ /print\(/)) print path ":" n ": debug: " t
      if (t ~ /sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[A-Z0-9]{12,}|xox[abpr]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY/) print path ":" n ": secret: " t
      if (t ~ /\/Users\/[a-z][a-z0-9._-]+\/|\/home\/[a-z][a-z0-9._-]+\/|C:\\Users\\/) print path ":" n ": local-path: " t
      # whole-word markers only (XXXX placeholders, TODOS etc. are not markers)
      if (t ~ /(^|[^A-Za-z])(TODO|FIXME|XXX)([^A-Za-z]|$)/ && t !~ /(TODO|FIXME|XXX)[(: ]*(T[0-9]+|#[0-9]+|[A-Z][A-Z0-9]+-[0-9]+)/) print path ":" n ": todo-without-ticket: " t
    }'
}

if [ "${1:-}" = "--stdin" ]; then
  fpath="${2:-unknown}"
  awk '{print NR "\t" $0}' | scan_text "$fpath"
  exit 0
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo — use --stdin"; exit 0; }
# Added lines from tracked changes (staged + unstaged) with their new line numbers
git diff HEAD --unified=0 --no-color 2>/dev/null | awk '
  /^\+\+\+ b\// { file=substr($0,7); next }
  /^@@/ { split($3, a, ","); n=substr(a[1],2)+0; next }
  /^\+/ && file != "" { print file "\t" n "\t" substr($0,2); n++ }
' | while IFS=$'\t' read -r f n t; do printf '%s\t%s\n' "$n" "$t" | scan_text "$f"; done
# Untracked files: every line is new
git ls-files --others --exclude-standard 2>/dev/null | while read -r f; do
  [ -f "$f" ] || continue
  case "$f" in *.lock|*.min.js|*.map|*.png|*.jpg|*.pdf|*.svg) continue ;; esac
  awk '{print NR "\t" $0}' "$f" | scan_text "$f"
done
exit 0
