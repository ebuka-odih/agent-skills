#!/usr/bin/env bash
# Tests for product plugin scripts. Usage: bash plugins/product/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX="$ROOT/tests/fixtures/project"
. "$ROOT/scripts/parse.sh"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }

SPEC="$FIX/docs/spec/SPEC.md"; PLAN="$FIX/docs/plan/PLAN.md"

echo "parsers"
reqs=$(spec_requirements "$SPEC")
check "finds 6 requirements"              '[ "$(grep -c . <<<"$reqs")" -eq 6 ]'
check "R1 status met"                     'grep -q "^R1	must	met$" <<<"$reqs"'
check "R5 priority should"                'grep -q "^R5	should	open$" <<<"$reqs"'
check "R6 dropped"                        'grep -q "^R6	could	dropped" <<<"$reqs"'
ms=$(plan_milestones "$PLAN")
check "2 milestones, M1 active"           '[ "$(grep -c . <<<"$ms")" -eq 2 ] && grep -q "^M1	Voting	active$" <<<"$ms"'
tasks=$(plan_tasks "$PLAN")
check "7 tasks parsed"                    '[ "$(grep -c . <<<"$tasks")" -eq 7 ]'
check "T6 blocked with note"              'grep -q "^M1	!	T6	Deploy to staging	setup	T1	waiting for hosting account$" <<<"$tasks"'
check "T4 covers R3, depends T3"          'grep -q "	T4	.*	R3	T3	" <<<"$tasks"'
check "deferred lists R5"                 '[ "$(plan_deferred "$PLAN")" = "R5" ]'

echo "ready logic"
ready=$(plan_ready "$PLAN")
check "T4 ready (T3 done)"                'grep -q "^T4	" <<<"$ready"'
check "T5 not ready (T4 open)"            '! grep -q "^T5	" <<<"$ready"'
check "T6 blocked → not ready"            '! grep -q "^T6	" <<<"$ready"'

echo "trace"
out=$(bash "$ROOT/scripts/trace.sh" "$SPEC" "$PLAN")
check "active milestone progress 1/5"     'grep -q "Active milestone: M1 — Voting (1/5 tasks done)" <<<"$out"'
check "next ready is T4"                  'grep -A1 "## Next ready" <<<"$out" | grep -q "T4 · Cast and change a vote"'
check "blocked shows T6 + reason"         'grep -q "T6 · Deploy to staging — waiting for hosting account" <<<"$out"'
check "must count 4, met 1"               'grep -q "must: 4 · met: 1" <<<"$out"'
check "no uncovered (R5 deferred, R6 dropped)" 'grep -q "uncovered: none" <<<"$out"'
check "T7 flagged as covering nothing"    'grep -q "tasks covering nothing: T7" <<<"$out"'
check "shows last progress"               'grep -q "T3 \[x\]" <<<"$out"'

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SPEC" "$TMP/SPEC.md"; sed '/^- \[ \] T5/d; /^- R5/d' "$PLAN" > "$TMP/PLAN.md"
awk '{print} /^- \[ \] T7/{print "- [ ] T8 · Ghost · covers: R9 · depends: - · size: S"}' "$TMP/PLAN.md" > "$TMP/P2.md" && mv "$TMP/P2.md" "$TMP/PLAN.md"
out=$(bash "$ROOT/scripts/trace.sh" "$TMP/SPEC.md" "$TMP/PLAN.md")
check "uncovered R4 + R5 when tasks removed" 'grep -q "uncovered: R4(must) R5(should)" <<<"$out"'
check "dangling T8→R9 flagged"            'grep -q "unknown requirements: T8→R9" <<<"$out"'
out=$(bash "$ROOT/scripts/trace.sh" "$TMP/nope.md" "$TMP/PLAN.md")
check "missing spec → points to product-spec" 'grep -q "run the product-spec skill" <<<"$out"'

echo "session-start hook"
HOOK="$ROOT/scripts/plan-context.sh"
out=$(CLAUDE_PROJECT_DIR="$FIX" bash "$HOOK" <<<'{"hook_event_name":"SessionStart","cwd":"x"}')
ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "valid hook JSON, event SessionStart" '[ "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" = "SessionStart" ]'
check "context names active milestone"    'grep -q "Active milestone: M1 — Voting" <<<"$ctx"'
check "context names next ready T4"       'grep -q "Next ready task: T4 · Cast and change a vote (covers R3)" <<<"$ctx"'
check "context names blocked T6"          'grep -q "Blocked: T6" <<<"$ctx"'
check "context routes to next-task"       'grep -q "next-task skill" <<<"$ctx"'
mkdir -p "$TMP/empty"
out=$(CLAUDE_PROJECT_DIR="$TMP/empty" bash "$HOOK" <<<'{}')
check "silent in non-spec project"        '[ -z "$out" ]'
mkdir -p "$TMP/speconly/docs/spec"; cp "$SPEC" "$TMP/speconly/docs/spec/"
out=$(CLAUDE_PROJECT_DIR="$TMP/speconly" bash "$HOOK" <<<'{}')
check "spec without plan → asks for project-plan" 'jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "project-plan skill"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
