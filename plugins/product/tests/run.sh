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


echo "project loop (loop.sh)"
L="$ROOT/scripts/loop.sh"; LT="$(mktemp -d)"
lp() { bash "$L" next "$1" 2>&1; }
mk() { # dir [spec-text] → project with docs/spec/SPEC.md (if text) and nothing else
  rm -rf "$1"; mkdir -p "$1"; [ -n "${2:-}" ] && { mkdir -p "$1/docs/spec"; printf '%s\n' "$2" > "$1/docs/spec/SPEC.md"; }; return 0
}
doc() { mkdir -p "$1/$(dirname "$2")"; echo "# x" > "$1/$2"; }
alldesign() { for f in docs/architecture/ARCHITECTURE.md docs/security/SECURITY.md docs/ops/DELIVERY.md; do doc "$1" "$f"; done; }
plan() { mkdir -p "$1/docs/plan"; printf '%s\n' "${@:2}" > "$1/docs/plan/PLAN.md"; }
P="$LT/p"
mk "$P"
check "empty dir → product-spec"            'lp "$P" | grep -q "^product:product-spec — no docs/spec/SPEC.md"'
st=$(bash "$L" status "$P")
check "empty dir is greenfield"             'grep -q "^Mode: greenfield (0 source files) · Phase: foundation/define" <<<"$st"'
mk "$P" "# Spec
## Risks & unknowns
- [x] K1 · solved · prototype: a
- [ ] K2 · can the API give hours? · prototype: hours
## Open questions"
check "open risk → prototype"               'lp "$P" | grep -q "^product:prototype — unresolved risk in SPEC: K2 · can the API give hours?"'
mk "$P" "# Spec
## Risks & unknowns
- [x] K1 · solved
## Open questions
- [ ] K9 · not under Risks"
check "ticked risks / other sections ignored" 'lp "$P" | grep -q "^architecture:system-design"'
mk "$P" "# Spec
A tool for clinics."
check "spec only → system-design"           'lp "$P" | grep -q "^architecture:system-design — no docs/architecture/ARCHITECTURE.md"'
doc "$P" docs/architecture/ARCHITECTURE.md
check "→ security baseline"                 'lp "$P" | grep -q "^security:security-baseline"'
doc "$P" docs/security/SECURITY.md
check "→ delivery pipeline"                 'lp "$P" | grep -q "^devops:delivery-pipeline"'
doc "$P" docs/ops/DELIVERY.md
check "→ project-plan"                      'lp "$P" | grep -q "^product:project-plan — no docs/plan/PLAN.md"'
mk "$P" "# Spec
Uses an LLM to summarise reviews on a public dashboard; needs SEO for landing pages."
alldesign "$P"
check "AI words → ai-design first"          'lp "$P" | grep -q "^ai-engineering:ai-design"'
doc "$P" docs/ai/AI.md
check "dashboard → ui-system"               'lp "$P" | grep -q "^frontend:ui-system"'
doc "$P" docs/ui/UI.md
check "landing pages → seo-architecture"    'lp "$P" | grep -q "^seo:seo-architecture"'
mk "$P" "# Spec
Our data model and Google sign-in; a mail agent forwards invoices."
alldesign "$P"
check "model/Google/agent are not AI or SEO" 'lp "$P" | grep -q "^product:project-plan"'
mkdir -p "$P/node_modules/react"; echo '{"dependencies":{"react":"^19"}}' > "$P/package.json"
check "react in package.json → ui-system"   'lp "$P" | grep -q "^frontend:ui-system"'
rm -rf "$P/package.json" "$P/node_modules"
plan "$P" "## M0 — Foundations · status: active" "- [x] T1 · Setup · covers: setup" "- [~] T2 · Login · covers: R1" "- [ ] T3 · Logout · covers: R1"
check "in-progress task first"              'lp "$P" | grep -q "^product:next-task (continue) — task in progress: T2 · Login"'
plan "$P" "## M0 — Foundations · status: active" "- [x] T1 · Setup · covers: setup" "- [ ] T3 · Logout · covers: R1 · depends: T1"
check "ready task → next-task"              'lp "$P" | grep -q "^product:next-task — next ready task in M0: T3 · Logout"'
plan "$P" "## M0 — Foundations · status: active" "- [ ] T3 · Logout · covers: R1 · depends: T9" "- [!] T4 · Deploy · covers: R2 — no hosting"
check "only blocked/waiting → unblock"      'lp "$P" | grep -q "^product:next-task (unblock) — no ready task in M0 — blocked: T4 — no hosting"'
plan "$P" "## M0 — Foundations · status: active" "- [x] T1 · Setup · covers: setup"
check "all tasks done → close milestone"    'lp "$P" | grep -q "^product:project-plan (close M0)"'
plan "$P" "## M0 — Foundations · status: done" "- [x] T1 · Setup · covers: setup" "## M1 — Next · status: planned" "- [ ] T2 · X · covers: R2"
check "done milestone → release"            'lp "$P" | grep -q "^devops:release-and-rollback — milestone M0 is done but not released"'
plan "$P" "## M0 — Foundations · status: released" "- [x] T1 · Setup · covers: setup" "## M1 — Next · status: planned" "- [ ] T2 · X · covers: R2"
check "released + planned → activate"       'lp "$P" | grep -q "^product:project-plan (activate) — no active milestone — activate M1 — Next"'
plan "$P" "## M0 — Foundations · status: released" "- [x] T1 · Setup · covers: setup"
check "all released → operate/evolve"       'lp "$P" | grep -q "^product:project-loop (evolve)"'
check "evolve names observability"          'lp "$P" | grep -q "devops:observability"'
mk "$P" "# Spec
public pages and an LLM"
alldesign "$P"; for f in docs/ai/AI.md docs/ui/UI.md docs/seo/SEO.md; do doc "$P" $f; done
plan "$P" "## M0 — Foundations · status: released" "- [x] T1 · Setup · covers: setup"
check "evolve adds search-console + ai-learnings" 'lp "$P" | grep -q "seo:search-console, ai-engineering:ai-learnings"'
plan "$P" "## M0 — F · status: done" "- [x] T1 · Setup · covers: setup"
check "release mentions site-audit for SEO" 'lp "$P" | grep -q "seo:site-audit"'
# profile and detection
mk "$P" "# Spec
A dashboard with an LLM assistant on public landing pages.
## Profile
- ui: yes
- ai: no
- seo: no
## Risks & unknowns"
alldesign "$P"
st=$(bash "$L" status "$P")
check "profile wins over spec words"        'grep -q "Domains: ui=on(profile) ai=off(profile) seo=off(profile)" <<<"$st"'
check "profile ai: no skips ai-design"      'lp "$P" | grep -q "^frontend:ui-system"'
mk "$P" "# Spec
Internal batch job.
## Profile
- UI: Yes
- ai: yes"
alldesign "$P"; doc "$P" docs/ui/UI.md
check "profile keys/values case-insensitive" 'lp "$P" | grep -q "^ai-engineering:ai-design"'
st=$(bash "$L" status "$P")
check "unset key falls back to detection"   'grep -q "seo=off(detected)" <<<"$st"'
mk "$P" "# Spec
Internal tool.
## Profile
- ai: no"
alldesign "$P"; mkdir -p "$P/app"; echo 'url = "https://api.deepseek.com/v1/chat"' > "$P/app/llm.py"
st=$(bash "$L" status "$P")
check "LLM API host in code = mismatch"     'grep -q "Mismatch: profile says no to: ai" <<<"$st"'
mk "$P" "# Spec
Internal tool."
alldesign "$P"; mkdir -p "$P/app"; echo 'key = os.environ["ANTHROPIC_API_KEY"]' > "$P/app/llm.py"
check "API key env name → ai detected"      'lp "$P" | grep -q "^ai-engineering:ai-design"'
st=$(bash "$L" status "$P")
check "no profile → hint to add one"        'grep -q "No ## Profile in SPEC.md" <<<"$st"'
rm -rf "$P/app"; mkdir -p "$P/backend"; printf 'fastapi==0.115\npydantic-ai>=1.0\n' > "$P/backend/requirements.txt"
check "pydantic-ai in requirements → ai"   'lp "$P" | grep -q "^ai-engineering:ai-design"'
rm -rf "$P/backend"; mkdir -p "$P/web"; echo '{"dependencies":{"vue":"^3"}}' > "$P/web/package.json"
check "nested web/package.json vue → ui"    'lp "$P" | grep -q "^frontend:ui-system"'
rm -rf "$P/web"; mkdir -p "$P/public"; echo "User-agent: *" > "$P/public/robots.txt"
check "robots.txt in code → seo"            'lp "$P" | grep -q "^seo:seo-architecture"'
rm -rf "$P/public"; mkdir -p "$P/docs/notes"; echo "OPENAI_API_KEY" > "$P/docs/notes/x.txt"; echo "OPENAI_API_KEY" > "$P/README.md"
check "docs and markdown don't count"       'lp "$P" | grep -q "^product:project-plan"'
mkdir -p "$P/tests"; echo "OPENAI_API_KEY" > "$P/tests/test_keys.py"
check "test files don't count"              'lp "$P" | grep -q "^product:project-plan"'
rm -rf "$P/tests"
G="$LT/g"; mk "$G" "# Spec
Internal tool."; alldesign "$G"; (cd "$G" && git init -q); mkdir -p "$G/scratch"; echo "OPENAI_API_KEY" > "$G/scratch/x.py"
check "git repo: untracked files ignored"   'lp "$G" | grep -q "^product:project-plan"'
mk "$P" "# Spec
## Profile
- ui: no
- ai: yes
- seo: yes"
pl=$(bash "$L" plugins "$P")
check "plugins: valid settings JSON"        'jq -e ".enabledPlugins" <<<"$pl" >/dev/null'
check "plugins: off domains disabled"       '[ "$(jq ".enabledPlugins[\"frontend@ebuka-skills\"]" <<<"$pl")" = false ] && [ "$(jq ".enabledPlugins[\"ai-engineering@ebuka-skills\"]" <<<"$pl")" = true ] && [ "$(jq ".enabledPlugins[\"seo@ebuka-skills\"]" <<<"$pl")" = true ]'
check "plugins: core always on"             '[ "$(jq "[.enabledPlugins | to_entries[] | select(.value)] | length" <<<"$pl")" = 11 ] && [ "$(jq ".enabledPlugins[\"backend@ebuka-skills\"]" <<<"$pl")" = true ]'
check "json carries domains"                'bash "$L" json "$P" | jq -e ".domains | index(\"ui=off(profile)\")" >/dev/null'
# existing code
E="$LT/e"; mk "$E"; mkdir -p "$E/app" "$E/tests"
for i in $(seq 1 10); do echo "<?php" > "$E/app/f$i.php"; done
for i in $(seq 1 30); do echo x > "$E/tests/t$i.php"; done
check "≥10 source files → existing/adopt"  'lp "$E" | grep -q "^product:project-loop (adopt) — existing code (10 source files)"'
rm "$E/app/f10.php"
check "9 source files is greenfield"        'lp "$E" | grep -q "^product:product-spec"'
echo "<?php" > "$E/app/f10.php"; doc "$E" docs/project/BASELINE.md
check "baseline written → product-spec"     'lp "$E" | grep -q "^product:product-spec"'
st=$(bash "$L" status "$E")
check "status lists baseline as done"       'grep -q "✔ docs/project/BASELINE.md" <<<"$st"'
(cd "$E" && git init -q && git add app/f1.php && git -c user.name=t -c user.email=t@t commit -qm x)
rm -f "$E/docs/project/BASELINE.md"
check "git repo counts tracked files only"  'lp "$E" | grep -q "^product:product-spec"'
# json, status, log
mk "$P" "# Spec
public pages and an LLM"
alldesign "$P"; for f in docs/ai/AI.md docs/ui/UI.md docs/seo/SEO.md; do doc "$P" $f; done
plan "$P" "## M0 — F · status: done" "- [x] T1 · Setup · covers: setup"
check "json is valid with arrays"           'bash "$L" json "$P" | jq -e ".mode == \"greenfield\" and .phase == \"release\" and (.done | index(\"docs/plan/PLAN.md\")) and (.missing | length == 0)" >/dev/null'
out=$(cd "$P" && bash "$L" log build "T1 done · next: T2")
check "log creates LOOP.md"                 'grep -q "^- [0-9-]* · build · T1 done · next: T2$" "$P/docs/project/LOOP.md"'
(cd "$P" && bash "$L" log release "M0 released" >/dev/null)
st=$(bash "$L" status "$P")
check "log appends, status shows last"      '[ "$(grep -c "^- " "$P/docs/project/LOOP.md")" = 2 ] && grep -q "Last hand-off: .* · release · M0 released" <<<"$st"'
check "bad command exits 2"                 'bash "$L" nope "$P" >/dev/null; [ $? = 2 ]'
check "missing dir exits 2"                 'bash "$L" status "$LT/none" >/dev/null; [ $? = 2 ]'
hook=$(cd "$P" && echo "{\"cwd\":\"$P\"}" | CLAUDE_PROJECT_DIR="$P" bash "$ROOT/scripts/plan-context.sh")
check "session hook carries the loop step"  'jq -r .hookSpecificOutput.additionalContext <<<"$hook" | grep -q "Project loop next: devops:release-and-rollback"'
rm -rf "$LT"
echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
