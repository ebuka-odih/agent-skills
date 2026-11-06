#!/usr/bin/env bash
# Minimal mutation tester for bash hook scripts (no off-the-shelf tool mutates bash).
# Applies one mutation at a time, runs the plugin's test suite, and reports killed vs survived.
#
# Usage: tools/mutate-bash.sh <script> <test-command> [--max N]
#   e.g. tools/mutate-bash.sh plugins/devops/scripts/infra-guard.sh "bash plugins/devops/tests/run.sh"
#
# Operators (each applied to one line at a time):
#   decision   deny/ask/block calls and `&& issue error|warn` reports → no-op            (does a test notice the guard stopped guarding?)
#   compare    -gt→-ge  -lt→-le  -eq→-ne  = "true"→= "false"  = 1 ]→= 0 ]
#   rule       delete a guard rule, pattern-table entry, awk detection rule, or neutralise an exported regex
#   negate     `grep -q` → `! grep -q` on condition lines
# Survivors are listed with line numbers; equivalent mutants are possible — judge each one.
set -u
script="${1:?script}"; test_cmd="${2:?test command}"; max=200
[ "${3:-}" = "--max" ] && max="${4:-200}"
[ -f "$script" ] || { echo "no such script: $script"; exit 1; }

backup="$(mktemp)"; cp "$script" "$backup"
restore() { cp "$backup" "$script"; rm -f "$backup"; }
trap restore EXIT INT TERM

# Baseline must pass
if ! bash -c "$test_cmd" >/dev/null 2>&1; then echo "baseline tests fail — fix them before mutation testing"; exit 1; fi

total=0; killed=0; survivors=""
mutate_line() { # lineno sed-expression label
  local n="$1" expr="$2" label="$3" before after
  before=$(sed -n "${n}p" "$backup")
  after=$(printf '%s\n' "$before" | sed -E "$expr")
  [ "$before" = "$after" ] && return 0
  [ "$total" -ge "$max" ] && return 0
  total=$((total+1))
  # ENVIRON, not -v: awk -v would strip backslashes (\s, \b) and silently change the mutant
  MUT_N="$n" MUT_REPL="$after" awk 'NR==ENVIRON["MUT_N"]+0 {print ENVIRON["MUT_REPL"]; next} {print}' "$backup" > "$script"
  # sanity: exactly one line differs
  [ "$(diff "$backup" "$script" | grep -c '^>')" = 1 ] || { cp "$backup" "$script"; total=$((total-1)); return 0; }
  if bash -c "$test_cmd" >/dev/null 2>&1; then
    survivors="$survivors
  line $n [$label]: $(printf '%s' "$before" | sed -E 's/^[[:space:]]+//' | cut -c1-110)"
  else
    killed=$((killed+1))
  fi
  cp "$backup" "$script"
}

lines=$(wc -l < "$backup" | tr -d ' ')
for n in $(seq 1 "$lines"); do
  l=$(sed -n "${n}p" "$backup")
  case "$l" in ''|'#'*|[[:space:]]'#'*) continue ;; esac
  # decision: neutralise the call that blocks / asks
  mutate_line "$n" 's/(decide|block) (deny|ask)/: \2/' decision
  mutate_line "$n" 's/&& (ask|deny|block) "/\&\& : "/' decision
  mutate_line "$n" 's/^([[:space:]]*)(deny|block) "/\1: "/' decision
  mutate_line "$n" 's/(&&|\|\|) issue (error|warn) /\1 : /' decision
  # compare
  mutate_line "$n" 's/ -gt / -ge /' compare
  mutate_line "$n" 's/ -lt / -le /' compare
  mutate_line "$n" 's/ -eq / -ne /' compare
  mutate_line "$n" 's/= "true"/= "false"/' compare
  mutate_line "$n" 's/= 1 \]/= 0 ]/' compare
  # rule deletion: guard rules and pattern-table entries
  case "$l" in
    has\ *|*"  '"*'|'*"'"|*'grep -q'*'&& '*) mutate_line "$n" 's/.*/:/' rule ;;
  esac
  # redaction / substitution rules (sed -e 's/…/…/' lines)
  case "$l" in
    *"-e 's/"*) mutate_line "$n" 's/-e '"'"'s\//-e '"'"'s\/NEVER_MATCHES_/' rule ;;
  esac
  # awk detection rules (`if (…) print path …`) and exported pattern regexes
  case "$l" in
    *'if ('*') print path'*) mutate_line "$n" 's/.*/      # rule removed/' rule ;;
  esac
  case "$l" in
    export\ *_RE=*) mutate_line "$n" 's/=.*/="NEVER_MATCHES_XYZ"/' rule ;;
  esac
  # negate a condition
  case "$l" in
    *'if grep -q'*|*'&& grep -q'*) mutate_line "$n" 's/(if|&&) grep -q/\1 ! grep -q/' negate ;;
  esac
done

score=0; [ "$total" -gt 0 ] && score=$(( killed * 100 / total ))
echo "$script: $killed/$total mutants killed (MSI ${score}%)"
[ -n "$survivors" ] && echo "survivors:$survivors"
exit 0
