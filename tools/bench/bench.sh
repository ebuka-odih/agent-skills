#!/usr/bin/env bash
# Replay real tasks from finished projects and compare an agent WITH the skills against one WITHOUT.
#
#   bench.sh mine <repo> [--since 2026-01-01] [--limit 30]      candidate fix commits (touch tests or fix:)
#   bench.sh new  <name> --repo <path> --fix <commit> [--plugins a,b] [--cases dir]
#                                                               scaffold a case from a commit you shipped
#   bench.sh run  [--cases dir] [--case glob] [--runs N] [--arms with,without] [--out dir]
#   bench.sh score <case-dir> <workdir> [--reference-diff file] score a finished workdir (used by run)
#
# A case is <cases>/<name>/case.json:
#   { "repo": "/abs/path", "base": "<commit before the fix>", "fix": "<the commit you shipped>",
#     "task": "what the agent is asked", "plugins": ["seo", "frontend"], "setup": "npm ci",
#     "max_turns": 60, "timeout": 1800,
#     "checks": [ {"type":"hidden_tests","paths":["tests/test_x.py"],"run":"pytest -q tests/test_x.py","weight":3},
#                 {"type":"cmd","run":"npm test","weight":2},
#                 {"type":"grep","file":"web/nginx.conf","pattern":"location = /","weight":1},
#                 {"type":"grep","file":"src/a.ts","pattern":"console\\.log","absent":true,"weight":1},
#                 {"type":"llm","rubric":"PASS only if …","weight":3} ] }
# Cases describe private projects: keep them out of git (default dir bench-cases/ is gitignored).
# Env: BENCH_CLAUDE (agent command, default `claude`), BENCH_JUDGE (judge command, default `claude`),
#      BENCH_JUDGE_MODEL (default sonnet), BENCH_PLUGINS_ROOT (default <repo>/plugins).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/../.." && pwd)"
CLAUDE_CMD="${BENCH_CLAUDE:-claude}"; JUDGE_CMD="${BENCH_JUDGE:-claude}"; JUDGE_MODEL="${BENCH_JUDGE_MODEL:-sonnet}"
PLUGINS_ROOT="${BENCH_PLUGINS_ROOT:-$ROOT/plugins}"
command -v jq >/dev/null && command -v git >/dev/null || { echo "bench needs jq and git"; exit 2; }
die() { echo "bench: $*" >&2; exit 2; }

# ---------------------------------------------------------------- score <case-dir> <workdir> [--reference-diff f]
# Prints one JSON object: {score, max, passed, total, checks:[{type,label,weight,pass,detail}]}
score() {
  local cdir="$1" wd="$2" refdiff="" case="$1/case.json"
  [ "${3:-}" = "--reference-diff" ] && refdiff="${4:-}"
  [ -f "$case" ] || die "no case.json in $cdir"
  local n i results="[]" type w pass detail label
  n=$(jq '.checks | length' "$case")
  # the agent's own changes, captured before hidden tests are copied in
  (cd "$wd" && git add -A >/dev/null 2>&1 && git diff --cached "$(jq -r '.base' "$case")" -- . ':(exclude).bench-*') > "$wd/.bench-agent.diff" 2>/dev/null
  for ((i = 0; i < n; i++)); do
    type=$(jq -r ".checks[$i].type" "$case"); w=$(jq -r ".checks[$i].weight // 1" "$case")
    pass=false; detail=""
    case "$type" in
      cmd)
        label=$(jq -r ".checks[$i].run" "$case")
        if (cd "$wd" && bash -c "$label") > "$wd/.bench-check-$i.log" 2>&1; then pass=true; fi
        detail=$(tail -3 "$wd/.bench-check-$i.log" | tr '\n' ' ' | cut -c1-200) ;;
      hidden_tests)
        label="hidden tests from $(jq -r '.fix' "$case" | cut -c1-10)"
        local fix paths run; fix=$(jq -r '.fix' "$case"); run=$(jq -r ".checks[$i].run" "$case")
        paths=$(jq -r ".checks[$i].paths[]" "$case")
        # the agent never sees these files: they're copied in from the shipped fix only now
        # shellcheck disable=SC2086
        if (cd "$wd" && git checkout "$fix" -- $paths) >/dev/null 2>&1 && (cd "$wd" && bash -c "$run") > "$wd/.bench-check-$i.log" 2>&1; then pass=true; fi
        detail=$(tail -3 "$wd/.bench-check-$i.log" 2>/dev/null | tr '\n' ' ' | cut -c1-200) ;;
      grep)
        local file pat absent; file=$(jq -r ".checks[$i].file" "$case"); pat=$(jq -r ".checks[$i].pattern" "$case"); absent=$(jq -r ".checks[$i].absent // false" "$case")
        if [ "$absent" = true ]; then label="$file lacks /$pat/"; else label="$file has /$pat/"; fi
        local found=false; grep -qE -- "$pat" "$wd/$file" 2>/dev/null && found=true
        if [ "$absent" = true ]; then [ "$found" = false ] && pass=true; else [ "$found" = true ] && pass=true; fi
        detail="found=$found" ;;
      llm)
        label="judge: $(jq -r ".checks[$i].rubric" "$case" | head -1 | cut -c1-60)"
        local prompt verdict
        prompt="You are grading an AI coding agent's work on a real task. Answer ONLY with JSON {\"pass\": true|false, \"reason\": \"one sentence\"}.

TASK GIVEN TO THE AGENT:
$(jq -r '.task' "$case")

RUBRIC:
$(jq -r ".checks[$i].rubric" "$case")

AGENT'S CHANGES (git diff against the starting commit, truncated):
$(head -c 60000 "$wd/.bench-agent.diff")
$( [ -n "$refdiff" ] && [ -f "$refdiff" ] && printf '\nWHAT THE DEVELOPER ACTUALLY SHIPPED (reference, truncated; other correct solutions are fine):\n%s\n' "$(head -c 30000 "$refdiff")")"
        verdict=$(printf '%s' "$prompt" | $JUDGE_CMD -p --model "$JUDGE_MODEL" --output-format json --max-turns 1 2>/dev/null | jq -r '.result // empty' 2>/dev/null)
        verdict=$(printf '%s' "$verdict" | perl -0777 -ne 'print $1 if /(\{.*\})/s')
        if [ "$(printf '%s' "$verdict" | jq -r '.pass // false' 2>/dev/null)" = true ]; then pass=true; fi
        detail=$(printf '%s' "$verdict" | jq -r '.reason // "judge gave no verdict"' 2>/dev/null || echo "judge gave no verdict") ;;
      *) label="unknown check type '$type'"; detail="skipped" ;;
    esac
    results=$(jq -c --arg t "$type" --arg l "$label" --argjson w "$w" --argjson p "$pass" --arg d "$detail" '. + [{type:$t,label:$l,weight:$w,pass:$p,detail:$d}]' <<<"$results")
  done
  jq -c '{score: (map(select(.pass)) | map(.weight) | add // 0), max: (map(.weight) | add // 0),
          passed: (map(select(.pass)) | length), total: length, checks: .}
         | .ratio = (if .max > 0 then ((.score / .max) * 100 | floor) / 100 else 0 end)' <<<"$results"
}

# ---------------------------------------------------------------- run
run() {
  local cases="$ROOT/bench-cases" glob="*" runs=1 arms="with,without" out=""
  while [ $# -gt 0 ]; do case "$1" in
    --cases) cases="$2"; shift ;; --case) glob="$2"; shift ;; --runs) runs="$2"; shift ;;
    --arms) arms="$2"; shift ;; --out) out="$2"; shift ;; *) die "unknown option $1" ;; esac; shift; done
  [ -d "$cases" ] || die "no cases dir: $cases (create cases with: bench.sh new)"
  [ -n "$out" ] || out="$ROOT/bench-results/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$out"; : > "$out/runs.jsonl"
  local cdir name case arm r wd t0 dur meta flags p plugins setup
  for cdir in "$cases"/$glob/; do
    case="$cdir/case.json"; [ -f "$case" ] || continue
    name=$(basename "$cdir")
    jq -e '.repo and .base and .task and (.checks | length > 0)' "$case" >/dev/null 2>&1 || { echo "skip $name: case.json needs repo, base, task, checks"; continue; }
    local repo base; repo=$(jq -r '.repo' "$case"); base=$(jq -r '.base' "$case")
    git -C "$repo" cat-file -e "$base^{commit}" 2>/dev/null || { echo "skip $name: $base not in $repo"; continue; }
    # what the developer shipped, for the judge and the report
    local ref="$out/$name.reference.diff"; : > "$ref"
    jq -e '.fix' "$case" >/dev/null && git -C "$repo" diff "$base" "$(jq -r '.fix' "$case")" > "$ref" 2>/dev/null
    for arm in ${arms//,/ }; do
      for ((r = 1; r <= runs; r++)); do
        wd="$out/work/$name/$arm-$r"; mkdir -p "$(dirname "$wd")"
        git clone -q --no-hardlinks "$repo" "$wd" 2>/dev/null && git -C "$wd" checkout -q "$base" 2>/dev/null || { echo "skip $name: clone/checkout failed"; continue 2; }
        git -C "$wd" remote remove origin 2>/dev/null   # the agent can't push anywhere
        setup=$(jq -r '.setup // empty' "$case")
        [ -n "$setup" ] && (cd "$wd" && bash -c "$setup") > "$wd/.bench-setup.log" 2>&1
        flags=(--setting-sources project,local)   # never the user's installed plugins
        if [ "$arm" = with ]; then
          for p in $(jq -r '.plugins[]? // empty' "$case"); do
            [ -d "$PLUGINS_ROOT/$p" ] || { echo "  warn: plugin $p not found in $PLUGINS_ROOT"; continue; }
            flags+=(--plugin-dir "$PLUGINS_ROOT/$p")
          done
        fi
        echo "▶ $name [$arm $r/$runs]"
        t0=$(date +%s)
        (cd "$wd" && timeout_run "$(jq -r '.timeout // 1800' "$case")" $CLAUDE_CMD -p "$(jq -r '.task' "$case")" "${flags[@]}" \
            --output-format json --max-turns "$(jq -r '.max_turns // 60' "$case")" \
            --permission-mode acceptEdits --allowedTools "Bash Read Edit Write Glob Grep Skill") > "$wd/.bench-agent.json" 2> "$wd/.bench-agent.err"
        dur=$(( $(date +%s) - t0 ))
        meta=$(jq -c '{turns: (.num_turns // null), cost: (.total_cost_usd // null), error: (if .is_error then (.result // "error") else null end)}' "$wd/.bench-agent.json" 2>/dev/null || echo '{"turns":null,"cost":null,"error":"no JSON from agent"}')
        local files lines; files=$(cd "$wd" && git add -A >/dev/null 2>&1; git diff --cached --name-only "$base" -- . ':(exclude).bench-*' | grep -c .)
        lines=$(cd "$wd" && git diff --cached --numstat "$base" -- . ':(exclude).bench-*' | awk '{a+=$1; d+=$2} END {print a+d+0}')
        local s
        if [ "$(jq -r '.error // empty' <<<"$meta")" != "" ]; then
          # the agent never worked (usage limit, crash, timeout): don't let a 0 drag the average down
          s='{"graded":false,"score":0,"max":0,"passed":0,"total":0,"ratio":0,"checks":[]}'
        else
          s=$(score "$cdir" "$wd" --reference-diff "$ref" | jq -c '. + {graded: true}')
        fi
        jq -c -n --arg case "$name" --arg arm "$arm" --argjson run "$r" --argjson dur "$dur" --argjson meta "$meta" \
          --argjson files "$files" --argjson lines "$lines" --argjson s "$s" \
          '{case:$case, arm:$arm, run:$run, duration_s:$dur, files_changed:$files, lines_changed:$lines} + $meta + $s' >> "$out/runs.jsonl"
        [ "$(jq -r .graded <<<"$s")" = false ] && { echo "  not graded — agent error: $(jq -r '.error' <<<"$meta" | cut -c1-120)"; continue; }
        echo "  score $(jq -r '.ratio' <<<"$s") ($(jq -r '"\(.passed)/\(.total)"' <<<"$s") checks) · $(jq -r '.turns // "?"' <<<"$meta") turns · \$$(jq -r '.cost // "?"' <<<"$meta") · ${dur}s"
      done
    done
  done
  report "$out"
}

timeout_run() { # seconds cmd… — portable timeout (macOS has no `timeout` by default)
  local secs="$1"; shift
  if command -v timeout >/dev/null; then timeout "$secs" "$@"; return $?; fi
  "$@" & local pid=$!
  ( sleep "$secs"; kill "$pid" 2>/dev/null ) & local w=$!
  wait "$pid"; local rc=$?; kill "$w" 2>/dev/null; wait "$w" 2>/dev/null; return $rc
}

# ---------------------------------------------------------------- report <out-dir>
report() {
  local out="$1"
  [ -s "$out/runs.jsonl" ] || { echo "no runs recorded"; return 1; }
  jq -s '
    group_by(.case) | map({
      case: .[0].case,
      arms: (group_by(.arm) | map((map(select(.graded != false))) as $g | { arm: .[0].arm, runs: length, graded: ($g | length),
        score: (if ($g | length) > 0 then (($g | map(.ratio) | add) / ($g | length) * 100 | floor / 100) else null end),
        checks: ($g | map("\(.passed)/\(.total)") | join(" ")),
        turns: (map(.turns // empty) | if length > 0 then (add / length | floor) else null end),
        cost: (map(.cost // empty) | if length > 0 then (add / length * 100 | floor / 100) else null end),
        duration_s: ((map(.duration_s) | add) / length | floor),
        files: ((map(.files_changed) | add) / length | floor),
        errors: (map(select(.error != null)) | length) }))
    }) | map(. + {delta: ((.arms | map(select(.arm == "with")) | .[0].score // null) as $w
                          | (.arms | map(select(.arm == "without")) | .[0].score // null) as $o
                          | if $w != null and $o != null then (($w - $o) * 100 | round / 100) else null end)})' "$out/runs.jsonl" > "$out/results.json"
  {
    echo "# Benchmark — $(basename "$out")"
    echo
    echo "| Case | Arm | Score | Checks | Graded | Turns | Cost \$ | Time | Files | Errors |"
    echo "|---|---|---|---|---|---|---|---|---|---|"
    jq -r '.[] | .case as $c | .arms[] | "| \($c) | \(.arm) | \(.score // "not graded") | \(if .checks == "" then "–" else .checks end) | \(.graded)/\(.runs) | \(.turns // "–") | \(.cost // "–") | \(.duration_s)s | \(.files) | \(.errors) |"' "$out/results.json"
    echo
    echo "| Case | Δ score (with − without) |"
    echo "|---|---|"
    jq -r '.[] | "| \(.case) | \(if .delta == null then "–" elif .delta > 0 then "+\(.delta)" else "\(.delta)" end) |"' "$out/results.json"
    echo
    echo "Failed checks:"
    jq -r 'if .graded == false then "- \(.case) [\(.arm) \(.run)]: not graded — \(.error | tostring | .[0:100])" else "- \(.case) [\(.arm) \(.run)]: " + ([.checks[] | select(.pass | not) | .label] | join("; ")) end' "$out/runs.jsonl" | grep -v ': $' || echo "- none"
  } > "$out/report.md"
  cat "$out/report.md"
}

# ---------------------------------------------------------------- new
new() {
  local name="${1:-}"; shift || true; local repo="" fix="" plugins="" cases="$ROOT/bench-cases"
  while [ $# -gt 0 ]; do case "$1" in --repo) repo="$2"; shift ;; --fix) fix="$2"; shift ;; --plugins) plugins="$2"; shift ;; --cases) cases="$2"; shift ;; *) die "unknown option $1" ;; esac; shift; done
  [ -n "$name" ] && [ -n "$repo" ] && [ -n "$fix" ] || die "usage: bench.sh new <name> --repo <path> --fix <commit> [--plugins a,b]"
  case "$name" in */*|.*) die "case name must be a plain folder name" ;; esac
  repo=$(cd "$repo" && pwd) || die "no repo $repo"
  local full base msg tests
  full=$(git -C "$repo" rev-parse "$fix^{commit}" 2>/dev/null) || die "$fix is not a commit in $repo"
  base=$(git -C "$repo" rev-parse "$full^" 2>/dev/null) || die "$fix has no parent"
  msg=$(git -C "$repo" log -1 --format=%B "$full")
  tests=$(git -C "$repo" diff --name-only --diff-filter=AM "$base" "$full" | grep -E '(^|/)(tests?|__tests__|spec)/|(_test|\.test|\.spec|Test)\.[a-z]+$|(^|/)test_[^/]+\.py$' || true)
  [ -e "$cases/$name" ] && die "$cases/$name already exists"
  mkdir -p "$cases/$name"
  jq -n --arg repo "$repo" --arg base "$base" --arg fix "$full" --arg msg "$msg" --arg plugins "$plugins" --arg tests "$tests" '
    { repo: $repo, base: $base, fix: $fix,
      task: ("EDIT ME: rewrite as the request you would give an agent (do not leak the solution). Commit was: " + ($msg | split("\n")[0])),
      plugins: ($plugins | split(",") | map(select(length > 0))),
      setup: "", max_turns: 60, timeout: 1800,
      checks: ((if ($tests | length) > 0 then [{type: "hidden_tests", paths: ($tests | split("\n") | map(select(length > 0))), run: "EDIT ME: command that runs these tests", weight: 3}] else [] end)
               + [{type: "llm", rubric: "EDIT ME: PASS only if … (what the shipped fix achieved)", weight: 3}]) }' > "$cases/$name/case.json"
  echo "created $cases/$name/case.json (base ${base:0:10} = parent of ${full:0:10})"
  [ -n "$tests" ] && echo "hidden tests: $(echo "$tests" | tr '\n' ' ')" || echo "no test files changed by the fix — add cmd/grep/llm checks"
  echo "next: edit the EDIT ME fields (task wording, test command, rubric), then: bench.sh run --case $name"
}

# ---------------------------------------------------------------- mine
mine() {
  local repo="${1:-}"; shift || true; local since="" limit=30
  while [ $# -gt 0 ]; do case "$1" in --since) since="$2"; shift ;; --limit) limit="$2"; shift ;; *) die "unknown option $1" ;; esac; shift; done
  [ -n "$repo" ] && git -C "$repo" rev-parse >/dev/null 2>&1 || die "usage: bench.sh mine <repo> [--since date] [--limit N]"
  echo "Candidate tasks (single-parent commits; ★ = changed test files → hidden tests available):"
  git -C "$repo" log --branches --no-merges ${since:+--since="$since"} --format='%H%x09%ad%x09%s' --date=short | while IFS=$'\t' read -r h d s; do
    local t; t=$(git -C "$repo" diff --name-only "$h^" "$h" 2>/dev/null | grep -cE '(^|/)(tests?|__tests__|spec)/|(_test|\.test|\.spec|Test)\.[a-z]+$|(^|/)test_[^/]+\.py$')
    case "$s" in fix*|feat*|perf*|refactor*) ;; *) [ "$t" -gt 0 ] || continue ;; esac
    printf '%s %s %s  %s\n' "$( [ "$t" -gt 0 ] && echo '★' || echo ' ')" "${h:0:10}" "$d" "$s"
  done | head -"$limit"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  run) run "$@" ;;
  score) [ $# -ge 2 ] || die "usage: bench.sh score <case-dir> <workdir> [--reference-diff file]"; score "$@" ;;
  report) [ -n "${1:-}" ] || die "usage: bench.sh report <results-dir>"; report "$1" ;;
  new) new "$@" ;;
  mine) mine "$@" ;;
  *) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
