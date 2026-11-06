#!/usr/bin/env bash
# Tests for the benchmark harness with a fake agent and a fake judge. Usage: bash tools/bench/tests/run.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; B="$HERE/bench.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
has()  { grep -qF -- "$2" <<<"$1"; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# --- a finished project: commit 1 has the bug, commit 2 is the fix you shipped (with a test)
R="$TMP/project"; mkdir -p "$R"; git -C "$R" init -q
printf '#!/usr/bin/env bash\n# BUG: subtracts\necho $(( $1 - $2 ))\n' > "$R/add.sh"
git -C "$R" add -A; git -C "$R" commit -qm "feat: add command"
BASE=$(git -C "$R" rev-parse HEAD)
printf '#!/usr/bin/env bash\necho $(( $1 + $2 ))\n' > "$R/add.sh"; mkdir -p "$R/tests"
printf '[ "$(bash add.sh 2 3)" = 5 ]\n' > "$R/tests/test_add.sh"
git -C "$R" add -A; git -C "$R" commit -qm "fix: add adds instead of subtracting"
FIX=$(git -C "$R" rev-parse HEAD)
git -C "$R" checkout -q "$BASE"      # leave the source repo somewhere specific to prove it's untouched
SRC_HEAD=$(git -C "$R" rev-parse HEAD)

# --- fake agent: fixes the bug only when a plugin is loaded; records its args and what it could see
cat > "$TMP/fake-claude" <<'F'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_LOG"
ls tests >> "$FAKE_LOG.seen" 2>&1 || echo "no tests dir" >> "$FAKE_LOG.seen"
git remote >> "$FAKE_LOG.remotes"
case "$*" in *--plugin-dir*) printf '#!/usr/bin/env bash\necho $(( $1 + $2 ))\n' > add.sh
    echo '{"type":"system","subtype":"init"}'
    echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"code-standards:writing-code"}},{"type":"tool_use","name":"Read","input":{}}]}}'
    echo '{"type":"assistant","message":{"content":[{"type":"text","text":"x"},{"type":"tool_use","name":"Edit","input":{}},{"type":"tool_use","name":"Read","input":{}}]}}'
    echo '{"type":"result","num_turns":4,"total_cost_usd":0.12,"is_error":false,"result":"fixed"}' ;;
  *"FAIL_AGENT"*) echo '{"num_turns":1,"total_cost_usd":0.01,"is_error":true,"result":"boom"}' ;;
  *) echo '{"num_turns":9,"total_cost_usd":0.30,"is_error":false,"result":"looked around"}' ;; esac
F
# --- fake judge: passes when the agent diff adds the + fix; saves the prompt
cat > "$TMP/fake-judge" <<'F'
#!/usr/bin/env bash
p=$(cat); printf 'judge-args: %s\njudge-cwd: %s\n%s\n=====\n' "$*" "$PWD" "$p" >> "$FAKE_LOG.judge"
if printf '%s' "$p" | sed -n '/AGENT.S CHANGES/,/WHAT THE DEVELOPER/p' | grep -q '^+echo \$(( \$1 + \$2 ))'; then v='{"pass": true, "reason": "adds"}'; else v='{"pass": false, "reason": "still subtracts"}'; fi
jq -n --arg v "Verdict: $v" '{result: $v}'
F
chmod +x "$TMP/fake-claude" "$TMP/fake-judge"
export BENCH_CLAUDE="$TMP/fake-claude" BENCH_JUDGE="$TMP/fake-judge" FAKE_LOG="$TMP/agent.log"
mkdir -p "$TMP/plugins/seo"; export BENCH_PLUGINS_ROOT="$TMP/plugins"

C="$TMP/cases"; mkdir -p "$C/add-fix"
jq -n --arg r "$R" --arg b "$BASE" --arg f "$FIX" '{repo:$r, base:$b, fix:$f, task:"add.sh gives the wrong answer; fix it", plugins:["seo","missing-plugin"],
  checks:[{type:"hidden_tests",paths:["tests/test_add.sh"],run:"bash tests/test_add.sh",weight:3},
          {type:"grep",file:"add.sh",pattern:"\\$1 \\+ \\$2",weight:1},
          {type:"grep",file:"add.sh",pattern:"BUG",absent:true,weight:1},
          {type:"cmd",run:"test -f add.sh",weight:1},
          {type:"llm",rubric:"PASS only if add.sh adds",weight:2},
          {type:"bogus",weight:5}]}' > "$C/add-fix/case.json"

echo "run"
out=$(bash "$B" run --cases "$C" --out "$TMP/res" 2>&1)
J="$TMP/res/runs.jsonl"
w() { jq -r "select(.arm==\"with\") | $1" "$J"; }; o() { jq -r "select(.arm==\"without\") | $1" "$J"; }
check "one run per arm"                       '[ "$(wc -l < "$J" | tr -d " ")" = 2 ]'
check "with: all real checks pass (8/13)"     '[ "$(w .score)" = 8 ] && [ "$(w .max)" = 13 ] && [ "$(w .ratio)" = 0.61 ]'
check "without: only cmd passes (1/13)"       '[ "$(o .score)" = 1 ] && [ "$(o .passed)" = 1 ]'
check "hidden tests pass only with the fix"   '[ "$(w ".checks[0].pass")" = true ] && [ "$(o ".checks[0].pass")" = false ]'
check "grep present / absent"                 '[ "$(w ".checks[1].pass")" = true ] && [ "$(w ".checks[2].pass")" = true ] && [ "$(o ".checks[2].pass")" = false ]'
check "llm judge verdict parsed"              '[ "$(w ".checks[4].pass")" = true ] && [ "$(w ".checks[4].detail")" = adds ] && [ "$(o ".checks[4].detail")" = "still subtracts" ]'
check "unknown check type never passes"       '[ "$(w ".checks[5].pass")" = false ] && [ "$(w ".checks[5].detail")" = skipped ]'
check "stream-json: skills recorded"         '[ "$(w ".skills | join(\",\")")" = "code-standards:writing-code" ] && [ "$(o ".skills | length")" = 0 ]'
check "stream-json: tool counts recorded"     '[ "$(w ".tools.Read")" = 2 ] && [ "$(w ".tools.Edit")" = 1 ] && [ "$(w ".tools.Skill")" = 1 ]'
check "report lists skills and tools"         'grep -q "add-fix \[with 1\]: skills: code-standards:writing-code · tools: Read 2" "$TMP/res/report.md" && grep -q "add-fix \[without 1\]: skills: none" "$TMP/res/report.md"'
check "agent asked for a stream-json trace"   'grep -q -- "--output-format stream-json --verbose" "$FAKE_LOG"'
check "turns and cost recorded"               '[ "$(w .turns)" = 4 ] && [ "$(w .cost)" = 0.12 ] && [ "$(o .turns)" = 9 ]'
check "files changed counted"                 '[ "$(w .files_changed)" = 1 ] && [ "$(o .files_changed)" = 0 ]'
check "with arm loads the case plugins"       'grep -- "--plugin-dir $TMP/plugins/seo" "$FAKE_LOG" | grep -q "add.sh gives"'
check "missing plugin warned, not loaded"     'has "$out" "plugin missing-plugin not found" && ! grep -q missing-plugin "$FAKE_LOG"'
check "without arm loads no plugins"          '[ "$(grep -c -- --plugin-dir "$FAKE_LOG")" = 1 ]'
check "both arms skip user settings"          '[ "$(grep -c -- "--setting-sources project,local" "$FAKE_LOG")" = 2 ]'
check "agent never sees the hidden tests"     '[ "$(grep -c "no tests dir" "$FAKE_LOG.seen")" = 2 ]'
check "clone has no remote to push to"        '[ ! -s "$FAKE_LOG.remotes" ]'
check "source repo untouched"                 '[ "$(git -C "$R" rev-parse HEAD)" = "$SRC_HEAD" ] && [ -z "$(git -C "$R" status --porcelain)" ]'
check "judge sees the shipped reference"      'grep -q "WHAT THE DEVELOPER ACTUALLY SHIPPED" "$FAKE_LOG.judge" && grep -q "^+\[ \"\$(bash add.sh 2 3)\" = 5 \]" "$FAKE_LOG.judge"'
check "judge diff excludes hidden tests"      '! sed -n "/AGENT.S CHANGES/,/WHAT THE DEVELOPER/p" "$FAKE_LOG.judge" | grep -q test_add'
check "report table rows"                     'grep -q "| add-fix | with | 0.61 | 5/6 | 1/1 | 4 | 0.12 |" "$TMP/res/report.md" && grep -q "| add-fix | without | 0.07 | 1/6 | 1/1 | 9 | 0.3 |" "$TMP/res/report.md"'
check "delta is with − without"               'grep -q "| add-fix | +0.54 |" "$TMP/res/report.md" && [ "$(jq ".[0].delta" "$TMP/res/results.json")" = 0.54 ]'
check "failed checks listed"                  'grep -q "add-fix \[without 1\]: hidden tests" "$TMP/res/report.md"'
check "progress line per run"                 'has "$out" "score 0.61 (5/6 checks) · 4 turns"'

check "judge runs without user settings"       'grep -q "judge-args: .*--setting-sources project,local" "$FAKE_LOG.judge"'
check "judge runs outside the repo"           '! grep -q "judge-cwd: $TMP/res" "$FAKE_LOG.judge" && ! grep -q "judge-cwd: $HERE" "$FAKE_LOG.judge"'
check "progress cost is rounded"              'has "$out" "· \$0.12 ·"'

echo "hidden tests are removed again"
HW="$TMP/hw"; git clone -q "$R" "$HW"; git -C "$HW" -c advice.detachedHead=false checkout -q "$BASE"
mkdir -p "$HW/tests"; echo "agent's own test" > "$HW/tests/test_add.sh"
mkdir -p "$TMP/hc/order"; jq '.checks = [{type:"hidden_tests",paths:["tests/test_add.sh"],run:"bash tests/test_add.sh",weight:1},{type:"cmd",run:"grep -q \"agent.s own test\" tests/test_add.sh",weight:1}]' "$C/add-fix/case.json" > "$TMP/hc/order/case.json"
hs=$(bash "$B" score "$TMP/hc/order" "$HW")
check "agent file at hidden path restored"    '[ "$(cat "$HW/tests/test_add.sh")" = "agent'"'"'s own test" ] && [ "$(jq -r ".checks[1].pass" <<<"$hs")" = true ]'
HW2="$TMP/hw2"; git clone -q "$R" "$HW2"; git -C "$HW2" -c advice.detachedHead=false checkout -q "$BASE"
bash "$B" score "$C/add-fix" "$HW2" >/dev/null
check "hidden test file gone after scoring"   '[ ! -e "$HW2/tests/test_add.sh" ] && ! git -C "$HW2" diff --cached --name-only | grep -q test_add'

echo "rescore"
cp "$C/add-fix/case.json" "$TMP/case.bak"
jq '.checks[4].rubric = "RESCORED rubric"' "$TMP/case.bak" > "$C/add-fix/case.json"
: > "$FAKE_LOG.judge"
rs=$(bash "$B" rescore "$TMP/res" --cases "$C" 2>&1)
check "rescore re-grades every run"           '[ "$(grep -c "^rescored add-fix" <<<"$rs")" = 2 ] && [ "$(wc -l < "$TMP/res/runs.jsonl" | tr -d " ")" = 2 ]'
check "rescore uses the new rubric"           'grep -q "RESCORED rubric" "$FAKE_LOG.judge"'
check "rescore keeps turns/cost"              '[ "$(jq -r "select(.arm==\"with\") | .turns" "$TMP/res/runs.jsonl")" = 4 ]'
check "rescore judge sees agent-only diff"    '! sed -n "/AGENT.S CHANGES/,/WHAT THE DEVELOPER/p" "$FAKE_LOG.judge" | grep -q test_add'
check "rescore keeps scores stable"           'grep -q "| add-fix | with | 0.61 |" "$TMP/res/report.md"'
cp "$TMP/case.bak" "$C/add-fix/case.json"
check "rescore without runs: exit 2"          'bash "$B" rescore "$TMP/nope" >/dev/null 2>&1; [ $? = 2 ]'

echo "options and errors"
: > "$FAKE_LOG"
bash "$B" run --cases "$C" --runs 2 --arms without --out "$TMP/res2" >/dev/null 2>&1
check "--runs 2 --arms without"               '[ "$(wc -l < "$TMP/res2/runs.jsonl" | tr -d " ")" = 2 ] && [ "$(jq -r .arm "$TMP/res2/runs.jsonl" | sort -u)" = without ]'
check "averages across runs"                  'grep -q "| add-fix | without | 0.07 |" "$TMP/res2/report.md" && [ "$(jq ".[0].arms[0].runs" "$TMP/res2/results.json")" = 2 ]'
check "no delta with one arm"                 'grep -q "| add-fix | – |" "$TMP/res2/report.md"'
mkdir -p "$C/err"; jq '.task = "FAIL_AGENT please"' "$C/add-fix/case.json" > "$C/err/case.json"
bash "$B" run --cases "$C" --case err --arms without --out "$TMP/res3" >/dev/null 2>&1
check "agent error counted"                   '[ "$(jq -r .error "$TMP/res3/runs.jsonl")" = boom ] && grep -q "| err | without | .* | 1 |$" "$TMP/res3/report.md"'
check "errored run is not graded"             '[ "$(jq -r .graded "$TMP/res3/runs.jsonl")" = false ] && grep -q "| err | without | not graded | – | 0/1 |" "$TMP/res3/report.md"'
check "ungraded run listed with its error"    'grep -q "err \[without 1\]: not graded — boom" "$TMP/res3/report.md"'
check "checks never run on an errored agent"  '[ "$(jq ".checks | length" "$TMP/res3/runs.jsonl")" = 0 ] && [ ! -f "$TMP/res3/work/err/without-1/.bench-agent.diff" ]'
printf '%s\n' '{"case":"m","arm":"with","run":1,"graded":true,"ratio":0.8,"passed":4,"total":5,"duration_s":10,"files_changed":1,"turns":3,"cost":0.1,"error":null,"checks":[]}' \
  '{"case":"m","arm":"with","run":2,"graded":false,"ratio":0,"passed":0,"total":0,"duration_s":2,"files_changed":0,"turns":1,"cost":0,"error":"limit","checks":[]}' \
  '{"case":"m","arm":"without","run":1,"graded":false,"ratio":0,"passed":0,"total":0,"duration_s":2,"files_changed":0,"turns":1,"cost":0,"error":"limit","checks":[]}' > "$TMP/mix.jsonl"
mkdir -p "$TMP/mix"; cp "$TMP/mix.jsonl" "$TMP/mix/runs.jsonl"; bash "$B" report "$TMP/mix" >/dev/null
check "average uses graded runs only"         'grep -q "| m | with | 0.8 | 4/5 | 1/2 |" "$TMP/mix/report.md"'
check "no delta when an arm has no grades"    '[ "$(jq ".[0].delta" "$TMP/mix/results.json")" = null ] && grep -q "| m | – |" "$TMP/mix/report.md"'
check "--case filters"                        '[ "$(jq -r .case "$TMP/res3/runs.jsonl" | sort -u)" = err ]'
mkdir -p "$C/badbase"; jq '.base = "0000000000000000000000000000000000000000"' "$C/add-fix/case.json" > "$C/badbase/case.json"
mkdir -p "$C/incomplete"; echo '{"repo":"x"}' > "$C/incomplete/case.json"
out=$(bash "$B" run --cases "$C" --case "[bi]*" --out "$TMP/res4" 2>&1)
check "unknown base commit skipped"           'has "$out" "skip badbase: 0000000000000000000000000000000000000000 not in"'
check "incomplete case skipped"               'has "$out" "skip incomplete: case.json needs repo, base, task, checks"'
check "missing cases dir: exit 2"             'bash "$B" run --cases "$TMP/nope" >/dev/null 2>&1; [ $? = 2 ]'
check "no command: usage, exit 2"             'bash "$B" >/dev/null 2>&1; [ $? = 2 ]'

printf '#!/usr/bin/env bash\ncat >/dev/null; echo "{\\"result\\": \\"\\"}"\n' > "$TMP/mute-judge"; chmod +x "$TMP/mute-judge"
JC="$TMP/jc"; mkdir -p "$JC/judgeonly"; jq '.checks = [{type:"llm",rubric:"x",weight:1}]' "$C/add-fix/case.json" > "$JC/judgeonly/case.json"
W0="$TMP/w0"; git clone -q "$R" "$W0"
js=$(BENCH_JUDGE="$TMP/mute-judge" bash "$B" score "$JC/judgeonly" "$W0")
check "empty judge answer → fail, says so"    '[ "$(jq -r ".checks[0].pass" <<<"$js")" = false ] && [ "$(jq -r ".checks[0].detail" <<<"$js")" = "judge gave no verdict" ]'

echo "score (standalone)"
W="$TMP/w"; git clone -q "$R" "$W"; git -C "$W" -c advice.detachedHead=false checkout -q "$BASE"
s=$(bash "$B" score "$C/add-fix" "$W")
check "score on untouched base"               '[ "$(jq .score <<<"$s")" = 1 ] && [ "$(jq .total <<<"$s")" = 6 ]'
mkdir -p "$C/empty"; jq '.checks = [{type:"grep",file:"add.sh",pattern:"x",weight:0}]' "$C/add-fix/case.json" > "$C/empty/case.json"
check "zero max weight → ratio 0"             '[ "$(bash "$B" score "$C/empty" "$W" | jq .ratio)" = 0 ]'

echo "new and mine"
out=$(bash "$B" new add-case --repo "$R" --fix "${FIX:0:8}" --plugins seo,testing --cases "$TMP/nc" 2>&1)
N="$TMP/nc/add-case/case.json"
check "base is the fix's parent"              '[ "$(jq -r .base "$N")" = "$BASE" ] && [ "$(jq -r .fix "$N")" = "$FIX" ]'
check "task carries the commit subject"       'jq -r .task "$N" | grep -q "EDIT ME.*fix: add adds instead of subtracting"'
check "hidden tests detected"                 '[ "$(jq -r ".checks[0].type" "$N")" = hidden_tests ] && [ "$(jq -r ".checks[0].paths[0]" "$N")" = tests/test_add.sh ]'
check "plugins split"                         '[ "$(jq -c .plugins "$N")" = "[\"seo\",\"testing\"]" ]'
check "llm rubric placeholder"                '[ "$(jq -r ".checks[-1].type" "$N")" = llm ]'
check "refuses to overwrite"                  '! bash "$B" new add-case --repo "$R" --fix "$FIX" --cases "$TMP/nc" >/dev/null 2>&1'
check "refuses path-like names"               '! bash "$B" new ../x --repo "$R" --fix "$FIX" --cases "$TMP/nc" >/dev/null 2>&1'
check "unknown commit fails"                  '! bash "$B" new y --repo "$R" --fix deadbeef --cases "$TMP/nc" >/dev/null 2>&1'
out=$(bash "$B" new feat-case --repo "$R" --fix "$FIX~1" --cases "$TMP/nc" 2>&1)
check "root commit has no parent → fails"     'has "$out" "has no parent"'
out=$(bash "$B" mine "$R")
check "mine stars commits with tests"         'has "$out" "★ ${FIX:0:10}" && has "$out" "fix: add adds"'
check "mine lists feat commits without star"  'grep -q "^  ${BASE:0:10}.*feat: add command" <<<"$out"'
lim=$(bash "$B" mine "$R" --limit 1)
check "mine --limit"                          '[ "$(tail -n +2 <<<"$lim" | grep -c .)" = 1 ]'
M2="$TMP/m2"; git init -q "$M2"; git -C "$M2" commit -q --allow-empty -m "docs: readme only"
mkdir -p "$M2/tests"; touch "$M2/tests/test_y.py"; git -C "$M2" add -A; git -C "$M2" commit -q -m "chore: add a test"
m2=$(bash "$B" mine "$M2")
check "mine skips other commits without tests" '! has "$m2" "docs: readme only"'
check "mine keeps any commit that adds tests"  'has "$m2" "chore: add a test"'
check "mine: not a repo → exit 2"             'bash "$B" mine "$TMP/nope" >/dev/null 2>&1; [ $? = 2 ]'

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
