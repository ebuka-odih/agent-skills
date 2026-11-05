#!/usr/bin/env bash
# Quick repo security scan: tracked secrets, tracked .env files, .gitignore gaps,
# and the dependency-audit commands for this stack. Read-only. Secret values are never printed.
# Usage: security-scan.sh [repo-root]
set -u
ROOT="${1:-.}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=patterns.sh
. "$HERE/patterns.sh"
cd "$ROOT" || exit 1
issues=0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repository — scan needs git to know what is tracked."; exit 0; }

echo "## Tracked .env files"
envs=$(git ls-files | grep -E '(^|/)\.env(\.[A-Za-z0-9_-]+)?$' | grep -vE '\.env\.(example|sample|dist|template)$')
if [ -n "$envs" ]; then sed 's/^/- TRACKED: /' <<<"$envs"; echo "  → git rm --cached <file>, add to .gitignore, and rotate every secret in it"; issues=$((issues+1)); else echo "- none"; fi
echo

echo "## Secrets in tracked files"
found=0
for entry in "${SECRET_PATTERNS[@]}"; do
  kind="${entry%%|*}"; re="${entry#*|}"
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    file="${hit%%:*}"; rest="${hit#*:}"; line="${rest%%:*}"; content="${rest#*:}"
    grep -qE -- "$PLACEHOLDER_RE" <<<"$(grep -oE -- "$re" <<<"$content" | head -1)" && continue
    case "$file" in *.lock|*lock.json|*.lock.yaml|*.min.js|*.map) continue ;; esac
    echo "- $file:$line · $kind (value hidden)"; found=1
  done < <(git grep -nIE -- "$re" 2>/dev/null)
done
[ "$found" = 1 ] && { echo "  → rotate first (secrets-and-deps leak-response), then move to config/env"; issues=$((issues+1)); } || echo "- none found in tracked files (history not scanned)"
echo

echo "## .gitignore"
is_app=0
for f in composer.json package.json pyproject.toml requirements.txt ./*/composer.json ./*/package.json ./*/pyproject.toml ./*/requirements.txt; do [ -e "$f" ] && is_app=1; done
git ls-files --others --cached | grep -qE '(^|/)\.env' && is_app=1
if [ "$is_app" = 0 ]; then echo "- no app manifest or .env files — skipped"; else
gi_missing=""
for want in .env; do git check-ignore -q "$want" 2>/dev/null || gi_missing="$gi_missing $want"; done
[ -f .env.example ] || [ -f .env.sample ] || ls ./*/.env.example >/dev/null 2>&1 || echo "- note: no .env.example — document required variables with placeholders"
if [ -n "$gi_missing" ]; then echo "- NOT ignored:$gi_missing"; issues=$((issues+1)); else echo "- .env is ignored"; fi
fi
echo

echo "## Dependency audits to run"
any=0
for d in . backend api server app web frontend client; do
  [ -d "$d" ] || continue
  [ -f "$d/composer.lock" ] || [ -f "$d/composer.json" ] && { echo "- $d: composer audit"; any=1; }
  if [ -f "$d/uv.lock" ]; then echo "- $d: uvx pip-audit"; any=1
  elif [ -f "$d/requirements.txt" ]; then echo "- $d: pip-audit -r requirements.txt"; any=1
  elif [ -f "$d/pyproject.toml" ]; then echo "- $d: pip-audit"; any=1; fi
  if [ -f "$d/pnpm-lock.yaml" ]; then echo "- $d: pnpm audit --prod"; any=1
  elif [ -f "$d/yarn.lock" ]; then echo "- $d: yarn npm audit"; any=1
  elif [ -f "$d/package-lock.json" ] || [ -f "$d/package.json" ]; then echo "- $d: npm audit --omit=dev"; any=1; fi
done
[ "$any" = 1 ] || echo "- no package manifests found"
echo

echo "## History scan"
if command -v gitleaks >/dev/null 2>&1; then echo "- run: gitleaks detect --source . --log-opts=--all"
elif command -v trufflehog >/dev/null 2>&1; then echo "- run: trufflehog git file://. --only-verified"
else echo "- install gitleaks or trufflehog to scan full git history (this scan only checks current files)"; fi
echo
echo "Result: $issues issue group(s) found."
exit 0
