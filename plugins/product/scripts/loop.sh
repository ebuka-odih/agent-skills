#!/usr/bin/env bash
# The project loop: work out where a project stands from the files every skill writes, and name the next skill.
#   loop.sh status [root]          phase, mode, contract files, next skill and why
#   loop.sh next   [root]          one line: <skill> — <why>
#   loop.sh json   [root]          {mode, phase, next, why, domains, mismatch, done:[…], missing:[…]}
#   loop.sh plugins [root]         project .claude/settings.json enabling only the plugins this project needs
#   loop.sh log <phase> <note…>    append a hand-off line to docs/project/LOOP.md (run from the project root)
# Read-only except `log`. Needs bash + awk (jq for json).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=parse.sh
. "$HERE/parse.sh"

cmd="${1:-status}"; shift || true
if [ "$cmd" = log ]; then
  phase="${1:?usage: loop.sh log <phase> <note>}"; shift
  mkdir -p docs/project
  [ -f docs/project/LOOP.md ] || printf '# Project loop — hand-off log\n\nEach line: date · phase · what was produced · what comes next. Written by skills when they finish; read by `loop.sh` and the next session.\n\n' > docs/project/LOOP.md
  printf -- '- %s · %s · %s\n' "$(date +%Y-%m-%d)" "$phase" "$*" >> docs/project/LOOP.md
  echo "logged to docs/project/LOOP.md"
  exit 0
fi
root="${1:-$PWD}"
[ -d "$root" ] || { echo "no such directory: $root"; exit 2; }
cd "$root" || exit 2

SPEC=docs/spec/SPEC.md; PLAN=docs/plan/PLAN.md; ARCH=docs/architecture/ARCHITECTURE.md
UI=docs/ui/UI.md; AI=docs/ai/AI.md; SEO=docs/seo/SEO.md; SEC=docs/security/SECURITY.md; DEL=docs/ops/DELIVERY.md
BASE=docs/project/BASELINE.md

# ---- signals
src_files() {
  { git ls-files 2>/dev/null || find . -type f -not -path './.git/*' -not -path '*/node_modules/*' -not -path './vendor/*'; } \
    | grep -E '\.(php|py|ts|tsx|js|jsx|go|rb|rs|java|kt|swift|vue|svelte)$' | grep -vE '(^|/)(docs|tests?|node_modules|vendor)/' | wc -l | tr -d ' '
}
nsrc=$(src_files)
mode=greenfield; [ "$nsrc" -ge 10 ] && mode=existing
spec_says() { [ -f "$SPEC" ] && grep -qiE "(^|[^[:alnum:]])($1)([^[:alnum:]]|$)" "$SPEC"; }   # whole words, case-insensitive
# Profile: "## Profile" in SPEC with lines like "ui: yes" / "ai: no" — the user's decision, wins over detection.
profile() { [ -f "$SPEC" ] && awk -v k="$1" 'BEGIN{IGNORECASE=1} /^## Profile/{on=1; next} /^## /{on=0} on { l=tolower($0); gsub(/^[[:space:]-]*/, "", l); if (index(l, k ":") == 1) { sub(/^[^:]*:[[:space:]]*/, "", l); print substr(l, 1, 3); exit } }' "$SPEC"; }
manifests() { find . -maxdepth 3 \( -name package.json -o -name requirements*.txt -o -name pyproject.toml -o -name composer.json \) -not -path '*/node_modules/*' -not -path './vendor/*' 2>/dev/null; }
deps_match() { manifests | xargs grep -lE "$1" 2>/dev/null | grep -q .; }
# detection from code and spec words (used only when the profile doesn't say)
code_mentions() { # ERE over tracked (or all) source/config files, not docs or markdown
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then git grep -qIE "$1" -- ':!docs' ':!*.md' ':!**/tests/**' ':!**/test/**' ':!**/fixtures/**' ':!**/evals/**' ':!*test*'
  else grep -rqIE "$1" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=docs --exclude-dir=tests --exclude-dir=test --exclude-dir=fixtures --exclude-dir=evals --exclude='*.md' --exclude='*test*' . 2>/dev/null; fi
}
# code evidence (used for detection AND for mismatch warnings)
code_ui()  { [ -f "$UI" ] || deps_match '"(react|vue|svelte|next|astro|solid-js|@inertiajs/[a-z-]+)"' || [ -d resources/views ]; }
code_ai()  { [ -f "$AI" ] || code_mentions 'api\.(openai|anthropic|deepseek|mistral|groq|together)\.(com|ai|xyz)|generativelanguage\.googleapis|(OPENAI|ANTHROPIC|DEEPSEEK|GEMINI|MISTRAL|GROQ|OPENROUTER)_API_KEY' || deps_match '"(openai|@anthropic-ai/sdk|ai|langchain|@langchain/[a-z-]+|ollama|cohere-ai)"|^(openai|anthropic|pydantic-ai|pydantic_ai|langchain|llama-index|ollama|litellm)([<>=~ ]|$)|"(openai|anthropic|pydantic-ai|langchain|litellm)[^"]*"|laravel/ai|openai-php'; }
code_seo() { [ -f "$SEO" ] || find . -maxdepth 4 \( -name 'robots.txt' -o -name 'sitemap*.xml' -o -name '*sitemap*.py' -o -name '*sitemap*.ts' -o -name '*sitemap*.php' \) -not -path '*/node_modules/*' -not -path './.git/*' 2>/dev/null | grep -q .; }
# detection when the profile is silent: code evidence or the spec's words
detect_ui()  { code_ui  || spec_says 'web ?app|dashboard|frontend|front-end|website|web page|landing page|UI'; }
detect_ai()  { code_ai  || spec_says 'AI|LLM|LLMs|GPT|OpenAI|Anthropic|embeddings?|RAG|chatbot|AI agents?|machine learning'; }
detect_seo() { code_seo || spec_says 'SEO|search engines?|organic search|rank on Google|public pages?|landing pages?|marketing site|blog'; }
domain_src=""   # "ui=profile:yes ai=detected:no …" for status output
need() { # ui|ai|seo → 0 if the project needs it
  local v; v=$(profile "$1")
  case "$v" in yes) domain_src="$domain_src $1=on(profile)"; return 0 ;; no) domain_src="$domain_src $1=off(profile)"; return 1 ;; esac
  if "detect_$1"; then domain_src="$domain_src $1=on(detected)"; return 0; fi
  domain_src="$domain_src $1=off(detected)"; return 1
}
mismatch=""
check_mismatch() { # profile says no, code says yes → tell the user
  local k; for k in ui ai seo; do [ "$(profile $k)" = no ] && "code_$k" && mismatch="$mismatch $k"; done; return 0
}
has_web()   { [ "${NEED_UI:-}" = 1 ]; }
needs_ai()  { [ "${NEED_AI:-}" = 1 ]; }
needs_seo() { [ "${NEED_SEO:-}" = 1 ]; }
open_risks() { # unresolved "- [ ] K…" lines under "## Risks"
  [ -f "$SPEC" ] || return 0
  awk '/^## Risks/{on=1; next} /^## /{on=0} on && /^[[:space:]]*- \[ \] K[0-9]+/' "$SPEC"
}

NEED_UI=0; NEED_AI=0; NEED_SEO=0
need ui && NEED_UI=1; need ai && NEED_AI=1; need seo && NEED_SEO=1
check_mismatch
done_list=(); missing=()
note() { if [ -f "$1" ]; then done_list+=("$1"); else missing+=("$1"); fi; }
note "$SPEC"; note "$ARCH"; note "$PLAN"
needs_ai && note "$AI"; has_web && note "$UI"; needs_seo && note "$SEO"
note "$SEC"; note "$DEL"
[ "$mode" = existing ] && note "$BASE"

# ---- decide (first unmet gate wins)
phase=""; next=""; why=""
set_next() { phase="$1"; next="$2"; why="$3"; }
if [ "$mode" = existing ] && [ ! -f "$BASE" ]; then
  set_next "adopt" "product:project-loop (adopt)" "existing code ($nsrc source files) without a baseline: recover SPEC/ARCHITECTURE from the code and run the scanners into $BASE before changing anything"
elif [ ! -f "$SPEC" ]; then
  set_next "foundation/define" "product:product-spec" "no $SPEC — what, for whom, what not, numbered requirements"
elif [ -n "$(open_risks)" ]; then
  r=$(open_risks | head -1 | sed -E 's/^[[:space:]]*- \[ \] //')
  set_next "foundation/prototype" "product:prototype" "unresolved risk in SPEC: $r — answer it cheaply before designing around it"
elif [ ! -f "$ARCH" ]; then
  set_next "foundation/design" "architecture:system-design" "no $ARCH"
elif needs_ai && [ ! -f "$AI" ]; then
  set_next "foundation/design" "ai-engineering:ai-design" "SPEC needs AI features and there is no $AI"
elif has_web && [ ! -f "$UI" ]; then
  set_next "foundation/design" "frontend:ui-system" "there is a web UI and no $UI (tokens, layers) — set it before screens multiply"
elif needs_seo && [ ! -f "$SEO" ]; then
  set_next "foundation/design" "seo:seo-architecture" "SPEC has public/search-facing pages and there is no $SEO"
elif [ ! -f "$SEC" ]; then
  set_next "foundation/design" "security:security-baseline" "no $SEC (auth, secrets, data, threats)"
elif [ ! -f "$DEL" ]; then
  set_next "foundation/design" "devops:delivery-pipeline" "no $DEL — CI and environments from day one, so every task ships through the same gates"
elif [ ! -f "$PLAN" ]; then
  set_next "foundation/plan" "product:project-plan" "no $PLAN — slice SPEC into milestones and tasks"
else
  active=$(plan_milestones "$PLAN" | awk -F'\t' '$3=="active"{print $1; exit}')
  inprog=$(plan_tasks "$PLAN" | awk -F'\t' '$2=="~"{print $3" · "$4; exit}')
  ready=$(plan_ready "$PLAN" | head -1 | awk -F'\t' '{print $1" · "$2}')
  open_in_active=$(plan_tasks "$PLAN" | awk -F'\t' -v m="$active" '$1==m && $2!="x"' | grep -c .)
  blocked=$(plan_tasks "$PLAN" | awk -F'\t' -v m="$active" '$1==m && $2=="!"{print $3" — "$7; exit}')
  done_ms=$(plan_milestones "$PLAN" | awk -F'\t' '$3=="done"{print $1; exit}')
  planned=$(plan_milestones "$PLAN" | awk -F'\t' '$3=="planned"{print $1" — "$2; exit}')
  if [ -n "$inprog" ]; then
    set_next "build" "product:next-task (continue)" "task in progress: $inprog — finish and verify it before starting another"
  elif [ -n "$done_ms" ]; then
    set_next "release" "devops:release-and-rollback" "milestone $done_ms is done but not released — release through $DEL, then mark it released$( needs_seo && printf ' (and run seo:site-audit on the deployed site)')"
  elif [ -n "$ready" ]; then
    set_next "build" "product:next-task" "next ready task in $active: $ready"
  elif [ -n "$active" ] && [ "$open_in_active" -gt 0 ]; then
    set_next "build/blocked" "product:next-task (unblock)" "no ready task in $active${blocked:+ — blocked: $blocked}; resolve the blocker or re-plan with project-plan"
  elif [ -n "$active" ]; then
    set_next "release" "product:project-plan (close $active)" "every task in $active is done — verify its requirements, set it to done, then release"
  elif [ -n "$planned" ]; then
    set_next "build" "product:project-plan (activate)" "no active milestone — activate $planned"
  else
    set_next "operate/evolve" "product:project-loop (evolve)" "everything planned is released — watch it (devops:observability$(needs_seo && printf ', seo:search-console')$(needs_ai && printf ', ai-engineering:ai-learnings')) and turn new requests or bugs into SPEC changes → project-plan"
  fi
fi

case "$cmd" in
  plugins) # project-level settings: switch off plugins this project doesn't need (their skill descriptions stop costing tokens)
    on() { [ "$1" = 1 ] && echo true || echo false; }
    printf '{\n  "enabledPlugins": {\n'
    for p in product agent-ops architecture backend code-standards testing security collaboration devops; do printf '    "%s@ebuka-skills": true,\n' "$p"; done
    printf '    "frontend@ebuka-skills": %s,\n    "ai-engineering@ebuka-skills": %s,\n    "seo@ebuka-skills": %s\n  }\n}\n' "$(on $NEED_UI)" "$(on $NEED_AI)" "$(on $NEED_SEO)"
    exit 0 ;;
  next) echo "$next — $why" ;;
  json)
    command -v jq >/dev/null || { echo "json needs jq"; exit 2; }
    jq -nc --arg mode "$mode" --arg phase "$phase" --arg domains "$domain_src" --arg mismatch "$mismatch" --arg next "$next" --arg why "$why" \
      --arg done "$(printf '%s\n' "${done_list[@]+"${done_list[@]}"}")" --arg missing "$(printf '%s\n' "${missing[@]+"${missing[@]}"}")" \
      '{mode:$mode, phase:$phase, next:$next, why:$why, domains:($domains|split(" ")|map(select(length>0))), mismatch:($mismatch|split(" ")|map(select(length>0))), done:($done|split("\n")|map(select(length>0))), missing:($missing|split("\n")|map(select(length>0)))}' ;;
  status)
    echo "Mode: $mode ($nsrc source files) · Phase: $phase"
    echo "Domains:$domain_src"
    [ -n "$mismatch" ] && echo "Mismatch: profile says no to:$mismatch — but the code uses it; update ## Profile in SPEC.md"
    [ -f "$SPEC" ] && [ -z "$(profile ui)$(profile ai)$(profile seo)" ] && echo "No ## Profile in SPEC.md — domains are detected; add one (ui/ai/seo: yes|no) to make routing explicit"
    echo "Contract files:"
    for f in "${done_list[@]+"${done_list[@]}"}"; do echo "  ✔ $f"; done
    for f in "${missing[@]+"${missing[@]}"}"; do echo "  · $f"; done
    [ -f docs/project/LOOP.md ] && { echo "Last hand-off: $(grep '^- ' docs/project/LOOP.md | tail -1 | sed 's/^- //')"; }
    echo "Next: $next"
    echo "Why:  $why" ;;
  *) echo "usage: loop.sh status|next|json|plugins [root] · loop.sh log <phase> <note>"; exit 2 ;;
esac
exit 0
