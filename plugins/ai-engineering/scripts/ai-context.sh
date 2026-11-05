#!/usr/bin/env bash
# SessionStart hook: report AI-architecture drift so the design keeps learning from the project.
# Silent for projects with no AI. Never blocks.
set -u
trap 'exit 0' ERR
exec 2>/dev/null
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
root="${CLAUDE_PROJECT_DIR:-${cwd:-$PWD}}"
AI="$root/docs/ai/AI.md"; SPEC="$root/docs/spec/SPEC.md"; LEARN="$root/docs/ai/LEARNINGS.md"

uses_ai() {
  grep -qiE 'pydantic-ai|pydantic_ai|"laravel/ai"|prism-php|openai-php|"openai"|^openai|anthropic|langchain|instructor|"ai":' \
    "$root"/requirements*.txt "$root"/pyproject.toml "$root"/backend/requirements*.txt "$root"/backend/pyproject.toml \
    "$root"/composer.json "$root"/package.json 2>/dev/null
}

notes=()
if [ ! -f "$AI" ]; then
  uses_ai || exit 0
  notes+=("AI libraries are in this project's dependencies but docs/ai/AI.md is missing — run the ai-design skill in Recover mode before adding or changing model calls.")
else
  ai_spec=$(sed -n 's/^spec_version:[[:space:]]*//p' "$AI" | head -1 | tr -d '[:space:]')
  if [ -f "$SPEC" ]; then
    spec_v=$(sed -n 's/^version:[[:space:]]*//p' "$SPEC" | head -1 | tr -d '[:space:]')
    if [ -n "$spec_v" ] && [ "$spec_v" != "${ai_spec:-}" ]; then
      notes+=("SPEC.md is version $spec_v but AI.md was checked against ${ai_spec:-none} — run ai-learnings step 3 to re-check AI features against the spec.")
    fi
  fi
  # Feature IDs listed in the AI.md feature table
  ids=$(awk '/^## Features/{on=1; next} /^## /{on=0} on && /^\| *F[0-9]+ *\|/' "$AI" | sed -E 's/^\| *(F[0-9]+).*/\1/' | sort -u)
  nocard=""; noeval=""
  for f in $ids; do
    ls "$root/docs/ai/features/${f}-"*.md >/dev/null 2>&1 || ls "$root/docs/ai/features/${f}.md" >/dev/null 2>&1 || nocard="$nocard $f"
    [ -d "$root/evals/ai/$f" ] || noeval="$noeval $f"
  done
  [ -n "$nocard" ] && notes+=("Features without a card:$nocard — run ai-feature for each.")
  [ -n "$noeval" ] && notes+=("Features without an eval set (evals/ai/<F-id>/):$noeval — run ai-evals.")
  if [ -f "$LEARN" ]; then
    pending=$(awk '/^## L[0-9]+/{if(c&&!p)n++; c=0; p=0} /scope:\**[[:space:]]*house-candidate/{c=1} /promoted:/{p=1} END{if(c&&!p)n++; print n+0}' "$LEARN")
    [ "${pending:-0}" -gt 0 ] && notes+=("$pending house-candidate learning(s) not yet promoted — offer the ai-learnings promotion step to the user.")
  fi
fi

[ ${#notes[@]} -gt 0 ] || exit 0
msg="ai-engineering: $(printf '%s ' "${notes[@]}")Before any model-call change, read docs/ai/AI.md and the feature card."
jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$m}}'
exit 0
