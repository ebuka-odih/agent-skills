#!/usr/bin/env bash
# Tests for collaboration scripts. Usage: bash plugins/collaboration/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/scripts/git-guard.sh"; PREP="$ROOT/scripts/pr-prep.sh"
FIX="$ROOT/../product/tests/fixtures/project"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
R="$TMP/repo"; mkdir -p "$R"; cd "$R"
git init -q -b main && git -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m "chore: init"
g() { # command → decision (allow when no output)
  local out; out=$(jq -nc --arg c "$1" --arg d "$R" '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}' | bash "$GUARD")
  if [ -z "$out" ]; then echo allow; else jq -r .hookSpecificOutput.permissionDecision <<<"$out"; fi
}
reason() { jq -nc --arg c "$1" --arg d "$R" '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}' | bash "$GUARD" | jq -r .hookSpecificOutput.permissionDecisionReason; }

echo "guard: non-git and safe commands"
check "ls allowed"                                  '[ "$(g "ls -la")" = allow ]'
check "git status allowed"                          '[ "$(g "git status -sb")" = allow ]'
edit_out=$(jq -nc '{tool_name:"Edit",tool_input:{}}' | bash "$GUARD")
check "non-Bash tool ignored"                       '[ -z "$edit_out" ]'

echo "guard: force push"
git switch -q -c feat/T4-vote
check "push --force on feature → deny (use lease)"  '[ "$(g "git push --force origin feat/T4-vote")" = deny ] && reason "git push --force origin feat/T4-vote" | grep -q force-with-lease'
check "push -f → deny"                              '[ "$(g "git push -f")" = deny ]'
check "push --force-with-lease on feature → allow"  '[ "$(g "git push --force-with-lease origin feat/T4-vote")" = allow ]'
check "lease to main → deny"                        '[ "$(g "git push --force-with-lease origin main")" = deny ]'
check "+refspec to master → deny"                   '[ "$(g "git push origin +HEAD:master")" = deny ]'
check "normal push → allow"                         '[ "$(g "git push -u origin HEAD")" = allow ]'
check "--no-verify → deny"                          '[ "$(g "git push --no-verify")" = deny ]'

echo "guard: commit messages"
git switch -q -c feat/no-task-x
check "conventional -m (no task branch) → allow"                     '[ "$(g "git commit -m \"feat(votes): let members change their vote\"")" = allow ]'
check "bad -m → deny"                               '[ "$(g "git commit -m \"updated stuff\"")" = deny ] && reason "git commit -m \"updated stuff\"" | grep -q "isn.t a Conventional Commit"'
check "single-quoted bad → deny"                    '[ "$(g "git commit -m '"'"'WIP'"'"'")" = deny ]'
check "too long subject → deny"                     '[ "$(g "git commit -m \"fix: $(printf "x%.0s" {1..80})\"")" = deny ]'
heredoc_ok=$'git commit -m "$(cat <<\'EOF\'\nfix(api): return 404 for missing clubs\n\nBody line.\nEOF\n)"'
heredoc_bad=$'git commit -F - <<\'EOF\'\nfixed the api\n\nEOF'
check "heredoc conventional → allow"                '[ "$(g "$heredoc_ok")" = allow ]'
check "heredoc bad → deny"                          '[ "$(g "$heredoc_bad")" = deny ]'
check "amend --no-edit (no message) → allow"        '[ "$(g "git commit --amend --no-edit")" = allow ]'
check "Merge subject → allow"                       '[ "$(g "git commit -m \"Merge branch main into x\"")" = allow ]'
check "commit --no-verify → deny"                   '[ "$(g "git commit --no-verify -m \"feat: x\"")" = deny ]'
git switch -q feat/T4-vote
check "task branch, message without T4 → deny"      '[ "$(g "git commit -m \"feat(votes): change vote\"")" = deny ] && reason "git commit -m \"feat(votes): change vote\"" | grep -q "Refs: T4"'
withref=$'git commit -F - <<\'EOF\'\nfeat(votes): change vote\n\nRefs: T4, R3\nEOF'
check "task branch, heredoc with Refs: T4 → allow"  '[ "$(g "$withref")" = allow ]'
check "chained cd && git commit bad → deny"         '[ "$(g "cd app && git add . && git commit -m \"stuff\"")" = deny ]'

echo "guard: committing on main"
git switch -q main
check "good commit on main → ask"                   '[ "$(g "git commit -m \"docs: fix typo\"")" = ask ]'
git config collab.allowMainCommits true
check "allowMainCommits → allow"                    '[ "$(g "git commit -m \"docs: fix typo\"")" = allow ]'
git config --unset collab.allowMainCommits
off_out=$(jq -nc --arg d "$R" '{tool_name:"Bash",tool_input:{command:"git push -f origin main"},cwd:$d}' | COLLAB_GUARD=off bash "$GUARD")
check "COLLAB_GUARD=off disables"                   '[ -z "$off_out" ]'

echo "pr-prep"
mkdir -p docs/spec docs/plan .agent-log/goals app
cp "$FIX/docs/spec/SPEC.md" docs/spec/; cp "$FIX/docs/plan/PLAN.md" docs/plan/
git add -A && git -c user.name=t -c user.email=t@example.invalid commit -q -m "docs: spec and plan"
git switch -q -c feat/T4-cast-vote
printf 'vote code\n' > app/votes.py
git add -A && git -c user.name=t -c user.email=t@example.invalid commit -q -m "feat(votes): cast and change a vote"
cat > .agent-log/goals/2026-11-05-t4-vote.md <<'EOF'
---
status: partial
task: T4
covers: R3
---
# Goal
## Acceptance criteria
- [x] C1: member can vote · check: `pytest -k vote`
- [ ] C2: second vote replaces first · check: `pytest -k change_vote` — BLOCKED: needs fixture data
## Evidence
- C1: PASS — `pytest -k vote` → 4 passed
EOF
out=$(bash "$PREP" main)
check "why names T4 + title + covers"              'grep -q "T4 · Cast and change a vote (covers R3)" <<<"$out"'
check "why quotes R3 requirement + accept"         'grep -q "R3\*\* (must) A member can cast one vote" <<<"$out" && grep -q "accept: second vote by the same member" <<<"$out"'
check "evidence from goal file"                    'grep -q "C1: PASS — .pytest -k vote. → 4 passed" <<<"$out"'
check "goal status shown"                          'grep -q "status: partial" <<<"$out"'
check "not done lists BLOCKED C2"                  'grep -A2 "## Not done" <<<"$out" | grep -q "C2: second vote replaces first"'
check "diff size counted"                          'grep -q "1 files, 1 changed lines" <<<"$out"'
check "files listed"                               'grep -q "^- app/votes.py" <<<"$out"'
git switch -q -c chore/no-task main
out=$(bash "$PREP" main)
check "no task → placeholder, no crash"            'grep -q "No task ID in branch" <<<"$out"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
