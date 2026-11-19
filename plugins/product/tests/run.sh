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
check "done milestone → release"            'lp "$P" | grep -q "^product:versioning — milestone M0 is done but not released"'
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
check "session hook carries the loop step"  'jq -r .hookSpecificOutput.additionalContext <<<"$hook" | grep -q "Project loop next: product:versioning"'
rm -rf "$LT"

echo "plan.sh (requests into the plan)"
PS="$ROOT/scripts/plan.sh"; PT="$(mktemp -d)"; PP="$PT/PLAN.md"; cp "$PLAN" "$PP"
pl() { bash "$PS" "$@" --file "$PP"; }
check "add → next free ID in the active milestone" '[ "$(pl add "Dark mode toggle" --covers R7)" = T8 ]'
check "line has the exact grammar"          'grep -qx -- "- \[ \] T8 · Dark mode toggle · covers: R7 · depends: - · size: S" "$PP"'
check "added after the last task of the milestone" '[ "$(grep -A1 "^- \[ \] T7 " "$PP" | tail -1)" = "- [ ] T8 · Dark mode toggle · covers: R7 · depends: - · size: S" ]'
check "parser sees it in M1"                '[ "$(plan_tasks "$PP" | awk -F"\t" "\$3==\"T8\"{print \$1}")" = M1 ]'
check "second add → T9 with depends + size" '[ "$(pl add "CSV export" --covers fix --depends T8 --size M)" = T9 ] && grep -q "T9 · CSV export · covers: fix · depends: T8 · size: M" "$PP"'
check "add to another milestone"            '[ "$(pl add "Later" --covers R5 --milestone M0)" = T10 ] && [ "$(plan_tasks "$PP" | awk -F"\t" "\$3==\"T10\"{print \$1}")" = M0 ]'
check "add without --covers refuses"        'pl add "x" >/dev/null 2>&1; [ $? = 2 ]'
check "size L refuses"                      'pl add "x" --covers R1 --size L >/dev/null 2>&1; [ $? = 2 ]'
check "title with · refuses"                'pl add "a · b" --covers R1 >/dev/null 2>&1; [ $? = 2 ]'
check "unknown milestone refuses"           'pl add "x" --covers R1 --milestone M9 >/dev/null 2>&1; [ $? = 1 ]'
check "updated: set to today"               'grep -q "^updated: $(date +%Y-%m-%d)$" "$PP"'
check "mark blocked needs a note"           'pl mark T4 "!" >/dev/null 2>&1; [ $? = 2 ]'
pl mark T4 "!" "waiting on design" >/dev/null
check "mark blocked with note"              'grep -q "^- \[!\] T4 · .* — waiting on design$" "$PP"'
pl mark T6 x >/dev/null
check "unblocking drops the blocker note"   'grep -qx -- "- \[x\] T6 · Deploy to staging · covers: setup · depends: T1 · size: S" "$PP"'
check "mark unknown task → 1"               'pl mark T99 x >/dev/null 2>&1; [ $? = 1 ]'
check "release with open tasks refuses"     'grep -q "still has open tasks: T5 T7 T8 T9" <<<"$(pl released M1 v0.2.0 2>&1)"'
for t in T4 T5 T7 T8 T9; do pl mark "$t" x >/dev/null; done
pl mark T10 "!" "needs the product name" >/dev/null
rel=$(pl released M1 v0.2.0)
check "released → status released"          '[ "$(plan_milestones "$PP" | awk -F"\t" "\$1==\"M1\"{print \$3}")" = released ]'
check "released: line under demo"           '[ "$(grep -A1 "^demo: add 2 candidates" "$PP" | tail -1)" = "released: v0.2.0 · $(date +%Y-%m-%d)" ]'
check "progress log line appended last"     '[ "$(tail -1 "$PP")" = "- $(date +%Y-%m-%d) · M1 released as v0.2.0" ]'
check "release lists blocked tasks to re-check" 'grep -q "T10 · Later — needs the product name" <<<"$rel"'
pl released M1 v0.2.1 >/dev/null
check "re-release replaces the released: line" '[ "$(grep -c "^released:" "$PP")" = 1 ] && grep -q "^released: v0.2.1" "$PP"'
check "release policy defaults to per-milestone" '[ "$(pl release-policy)" = per-milestone ]'
sed -i.bak 's/^updated:/release: per-feature   # per-feature | per-milestone | manual\nupdated:/' "$PP"
check "release policy read from front matter" '[ "$(pl release-policy)" = per-feature ]'
printf '# P\n\n## M1 — A · status: active\n- [ ] T1 · a · covers: R1 · depends: - · size: S\n' > "$PT/nolog.md"
bash "$PS" log "first entry" --file "$PT/nolog.md" >/dev/null
check "log creates ## Progress log when missing" '[ "$(grep -c "^## Progress log" "$PT/nolog.md")" = 1 ] && [ "$(tail -1 "$PT/nolog.md")" = "- $(date +%Y-%m-%d) · first entry" ]'
check "no PLAN.md → 1"                      'bash "$PS" add x --covers R1 --file "$PT/none.md" >/dev/null 2>&1; [ $? = 1 ]'
rm -rf "$PT"

echo "version.sh"
VS="$ROOT/scripts/version.sh"; VT="$(mktemp -d)"
g() { git -c user.name=t -c user.email=t@t.invalid -c tag.gpgSign=false "$@"; }
vs() { (cd "$VT" && bash "$VS" "$@"); }
(cd "$VT" && git init -q && mkdir -p App Tests/X \
  && printf '{\n  "name": "x",\n  "version": "0.3.0",\n  "deps": {"a": {"version": "9.9.9"}}\n}\n' > package.json \
  && printf '<plist><dict>\n<key>CFBundleShortVersionString</key>\n\t<string>0.3.0</string>\n<key>CFBundleVersion</key>\n\t<string>12</string>\n</dict></plist>\n' > App/Info.plist \
  && cp App/Info.plist Tests/X/Info.plist \
  && printf '# Changelog\n\nIntro.\n\n## 0.3.0 — 2026-11-01\n- first\n' > CHANGELOG.md \
  && g add -A && g commit -qm "feat: first" && g tag -a v0.3.0 -m v0.3.0)
check "detects package.json then Info.plist (not Tests/)" '[ "$(vs files | tr "\n" " ")" = "package.json App/Info.plist " ]'
check "current from the primary file"       '[ "$(vs current)" = 0.3.0 ]'
check "last tag"                            '[ "$(vs last-tag)" = v0.3.0 ]'
check "nothing since the tag → next exits 3" 'vs next >/dev/null; [ $? = 3 ]'
check "status says nothing unreleased"      'vs status | grep -q "nothing unreleased"'
check "check passes on a clean release"     'vs check | grep -q "✔ version 0.3.0 consistent (v0.3.0)"'
(cd "$VT" && echo a > a && g add a && g commit -qm "fix(ui): button alignment")
check "fix only → patch"                    '[ "$(vs next)" = 0.3.1 ]'
(cd "$VT" && echo b > b && g add b && g commit -qm "feat(recorder): phone recording")
check "feat → minor"                        '[ "$(vs next)" = 0.4.0 ]'
check "status counts unreleased commits"    'vs status | grep -q "2 unreleased commit(s) (1 feat, 0 breaking, 1 other) → next 0.4.0"'
check "explicit level wins"                 '[ "$(vs next patch)" = 0.3.1 ] && [ "$(vs next 2.0.0)" = 2.0.0 ]'
(cd "$VT" && echo c > c && g add c && g commit -qm "refactor!: drop the old format")
check "breaking at 0.x → minor, not 1.0"    '[ "$(vs next)" = 0.4.0 ]'
check "--path limits commits to a folder"   '(cd "$VT" && mkdir -p sub && echo s > sub/s && g add sub && g commit -qm "fix: sub only"); [ "$(vs next --path sub)" = 0.3.1 ]'
check "bump prints the new version"         '[ "$(vs bump)" = 0.4.0 ]'
check "bump wrote package.json (first version key only)" 'grep -q "\"version\": \"0.4.0\"" "$VT/package.json" && grep -q "\"version\": \"9.9.9\"" "$VT/package.json"'
check "bump wrote Info.plist short version" '[ "$(sed -n 3p "$VT/App/Info.plist")" = "	<string>0.4.0</string>" ]'
check "integer build number +1"             'grep -q "<string>13</string>" "$VT/App/Info.plist"'
check "Tests/ plist untouched"              'grep -q "<string>0.3.0</string>" "$VT/Tests/X/Info.plist"'
check "CHANGELOG section above the newest, intro kept" '[ "$(grep -n "^## " "$VT/CHANGELOG.md" | head -1)" = "5:## 0.4.0 — $(date +%Y-%m-%d)" ] && grep -q "^Intro.$" "$VT/CHANGELOG.md"'
check "CHANGELOG groups Breaking/Features/Fixes" 'grep -A1 "^### Breaking" "$VT/CHANGELOG.md" | grep -q "drop the old format" && grep -A1 "^### Features" "$VT/CHANGELOG.md" | grep -q "^- phone recording (recorder)$" && grep -A3 "^### Fixes" "$VT/CHANGELOG.md" | grep -q "^- button alignment (ui)$"'
check "status: bumped but not tagged"       'vs status | grep -q "0.4.0 is bumped but not tagged yet"'
check "next keeps a prepared bump"          '[ "$(vs next)" = 0.4.0 ]'
check "second bump doesn't duplicate the section" 'vs bump >/dev/null; [ "$(grep -c "^## 0.4.0" "$VT/CHANGELOG.md")" = 1 ]'
check "tag refuses a dirty tree"            'vs tag >/dev/null 2>&1; [ $? = 1 ]'
(cd "$VT" && g add -A && g commit -qm "chore(release): v0.4.0")
check "tag creates v0.4.0"                  '[ "$(cd "$VT" && g tag -l v0.4.0)" = "" ] && (cd "$VT" && bash "$VS" tag >/dev/null) && [ "$(cd "$VT" && git tag -l v0.4.0)" = v0.4.0 ]'
check "tag again refuses"                   'vs tag >/dev/null 2>&1; [ $? = 1 ]'
check "release commits don't count as unreleased" 'vs status | grep -q "nothing unreleased"'
check "verify: old build reported"          'grep -q "reports 0.3.0, expected 0.4.0" <<<"$(vs verify --cmd "echo App 0.3.0")"'
check "verify fails with exit 1"            'vs verify --cmd "echo App 0.3.0" >/dev/null; [ $? = 1 ]'
check "verify: current build passes"        'vs verify --cmd "echo v0.4.0" | grep -q "✔"'
mkdir -p "$VT/Fake.app/Contents"; cp "$VT/App/Info.plist" "$VT/Fake.app/Contents/Info.plist"
check "verify --app reads the bundle"       'vs verify --app "$VT/Fake.app" | grep -q "✔ .*reports 0.4.0"'
printf '{"version": "0.3.9"}\n' > "$VT/package.json"
check "check: files disagree → 1"           'grep -q "App/Info.plist says 0.4.0, primary says 0.3.9" <<<"$(vs check)"; vs check >/dev/null; [ $? = 1 ]'
check "check: behind the last tag"          'grep -q "behind the last tag v0.4.0" <<<"$(vs check)"'
printf '0.5.0\n' > "$VT/VERSION"
check "VERSION_FILES env picks the files"    '[ "$(cd "$VT" && VERSION_FILES="VERSION" bash "$VS" current)" = 0.5.0 ]'
check "--file overrides detection"          '[ "$(vs current --file VERSION)" = 0.5.0 ]'
check "check: CHANGELOG missing the section" 'grep -q "no section for 0.5.0" <<<"$(vs check --file VERSION)"'
check "pyproject [project] version"         'printf "[tool.x]\nversion = \"9\"\n[project]\nname = \"a\"\nversion = \"1.2.3\"\n" > "$VT/pyproject.toml"; [ "$(vs current --file pyproject.toml)" = 1.2.3 ]'
check "pyproject bump writes [project] only" 'vs bump 1.3.0 --file pyproject.toml >/dev/null; grep -q "^version = \"9\"" "$VT/pyproject.toml" && grep -q "^version = \"1.3.0\"" "$VT/pyproject.toml"'
check "prefix tags for monorepos"           '(cd "$VT" && g tag -a api-v2.0.0 -m x); [ "$(vs last-tag --prefix api-)" = api-v2.0.0 ] && [ "$(vs last-tag)" = v0.4.0 ]'
check "no version file → status says so"    'mkdir -p "$VT/empty" && (cd "$VT/empty" && bash "$VS" status) | grep -q "no version file"'
rm -rf "$VT"

echo "session hook: version + release due"
HT="$(mktemp -d)"; mkdir -p "$HT/docs/spec" "$HT/docs/plan"; cp "$SPEC" "$HT/docs/spec/"; cp "$PLAN" "$HT/docs/plan/"
(cd "$HT" && git init -q && echo '{"version": "0.2.0"}' > package.json && g add -A && g commit -qm "feat: x" && g tag -a v0.2.0 -m x && echo y > y && g add y && g commit -qm "feat: y")
hctx() { echo '{}' | CLAUDE_PROJECT_DIR="$HT" bash "$ROOT/scripts/plan-context.sh" | jq -r .hookSpecificOutput.additionalContext; }
check "hook shows the version line"         'hctx | grep -q "Version: 0.2.0 (package.json) · last tag v0.2.0 · 1 unreleased commit(s)"'
check "per-milestone: done milestone → release due" 'hctx | grep -q "Release due: milestone M0 is done but not released"'
sed -i.bak 's/^## M0 — Foundations · status: done/## M0 — Foundations · status: released/' "$HT/docs/plan/PLAN.md"
check "released milestone → nothing due"    '! hctx | grep -q "Release due"'
sed -i.bak 's/^updated:/release: per-feature\nupdated:/' "$HT/docs/plan/PLAN.md"
check "per-feature: unreleased feat → due"  'hctx | grep -q "Release due: a feature is merged but not released"'
rm -rf "$HT"
echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
