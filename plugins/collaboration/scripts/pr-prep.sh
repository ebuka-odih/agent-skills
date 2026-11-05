#!/usr/bin/env bash
# Draft a PR body from the repo: branch task ID → PLAN.md task → SPEC.md requirements →
# newest goal file for that task (criteria + evidence) → diff size and touched areas.
# Usage: pr-prep.sh [base-ref]   (default: origin/main, else main)
set -u
base="${1:-}"
if [ -z "$base" ]; then
  if git rev-parse --verify -q origin/main >/dev/null; then base=origin/main
  elif git rev-parse --verify -q main >/dev/null; then base=main
  else base=master; fi
fi
br=$(git branch --show-current)
task=$(grep -oE 'T[0-9]+' <<<"$br" | head -1)
PLAN=docs/plan/PLAN.md; SPEC=docs/spec/SPEC.md

line=""; covers=""; title=""
if [ -n "$task" ] && [ -f "$PLAN" ]; then
  line=$(grep -E "^[[:space:]]*- \[.\] $task · " "$PLAN" | head -1)
  title=$(sed -E 's/^[[:space:]]*- \[.\] T[0-9]+ · ([^·]+) ·.*/\1/' <<<"$line" | sed -E 's/[[:space:]]+$//')
  covers=$(grep -oE 'covers: [^·]+' <<<"$line" | sed -E 's/covers: //; s/[[:space:]]//g')
fi

goal=""
if [ -n "$task" ] && [ -d .agent-log/goals ]; then
  goal=$(grep -lE "^task:[[:space:]]*$task\b" .agent-log/goals/*.md 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
fi
[ -z "$goal" ] && [ -f .agent-log/GOAL.md ] && grep -qE "^task:[[:space:]]*${task:-NONE}\b" .agent-log/GOAL.md && goal=.agent-log/GOAL.md

mb=$(git merge-base "$base" HEAD 2>/dev/null || echo "$base")
files=$(git diff --name-only "$mb"...HEAD 2>/dev/null; git diff --name-only 2>/dev/null)
files=$(sort -u <<<"$files" | grep .)
counted=$(git diff --numstat "$mb"...HEAD 2>/dev/null | grep -vE '(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|composer\.lock|poetry\.lock|uv\.lock|\.snap)$' | awk '{a+=$1; d+=$2} END{print a+d+0}')

echo "## Why"
if [ -n "$line" ]; then
  echo "$task · $title${covers:+ (covers $covers)}"
  if [ -f "$SPEC" ] && [ -n "$covers" ]; then
    IFS=',' read -ra rs <<<"$covers"
    for r in "${rs[@]}"; do
      case "$r" in setup|-|"") continue ;; esac
      req=$(grep -E "^[[:space:]]*- \*\*$r\*\*" "$SPEC" | head -1 | sed -E 's/^[[:space:]]*- //')
      acc=$(awk -v r="$r" '$0 ~ "\\*\\*"r"\\*\\*" {f=1; next} f && /accept:/ {sub(/^[[:space:]]*/,""); print; exit} f && /^[[:space:]]*- \*\*/ {exit}' "$SPEC")
      [ -n "$req" ] && echo "- $req" && [ -n "$acc" ] && echo "  $acc"
    done
  fi
else
  echo "<!-- No task ID in branch '$br' or no docs/plan/PLAN.md — describe the request here -->"
fi
echo
echo "## What changed"
echo "<!-- 3–6 bullets, behaviour first -->"
echo
echo "## Evidence"
if [ -n "$goal" ]; then
  echo "From \`$goal\` (status: $(sed -n 's/^status:[[:space:]]*//p' "$goal" | head -1)):"
  echo
  grep -E '^[[:space:]]*- \[[ x~]\] C[0-9]+' "$goal" | sed -E 's/^[[:space:]]*//'
  echo
  awk '/^## Evidence/{f=1; next} /^## /{f=0} f && NF' "$goal"
else
  echo "<!-- No goal file for ${task:-this branch} — run verify-done (agent-ops) and paste command → result per criterion -->"
fi
echo
echo "## Not done"
if [ -n "$goal" ]; then
  nd=$(grep -E '^[[:space:]]*- \[[ ~]\] C[0-9]+' "$goal" | sed -E 's/^[[:space:]]*//')
  if [ -n "$nd" ]; then echo "$nd"; else echo "Nothing — every criterion passed."; fi
else
  echo "<!-- list FAIL / BLOCKED / manual items, or 'Nothing' -->"
fi
echo
echo "## Risk and rollout"
echo "- Diff: $(grep -c . <<<"$files") files, $counted changed lines (excl. lockfiles)$( [ "$counted" -gt 400 ] && echo ' — over 400: split or explain')"
grep -qE '(^|/)migrations?/|database/migrations/|alembic/versions/' <<<"$files" && echo "- Contains migrations — confirm expand → migrate → contract"
grep -qE '^docs/architecture/' <<<"$files" && echo "- Changes docs/architecture — needs an ADR for any changed decision"
if [ -f docs/ai/AI.md ] && grep -qiE '(^|/)(ai|agents?|prompts?|llm)/|embeddings' <<<"$files"; then
  echo "- Touches AI code — run ai-design check mode and attach the eval result"
fi
[ -f docs/architecture/ARCHITECTURE.md ] && echo "- Architecture check: <paste system-design check-mode result>"
echo
echo "## How to review"
echo "<!-- where to start; how to run it -->"
echo
echo "<details><summary>Files</summary>"
echo
sed 's/^/- /' <<<"$files"
echo
echo "</details>"
