#!/usr/bin/env bash
# Read-only delivery scan: CI provider and job coverage, deploy target, Docker, IaC, basics.
# Usage: devops-scan.sh [repo-root]
set -u
ROOT="${1:-.}"
cd "$ROOT" || exit 1
gaps=0
gap() { echo "- GAP: $1"; gaps=$((gaps+1)); }

echo "## CI"
wf=$(ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null)
if [ -n "$wf" ]; then
  echo "- GitHub Actions: $(echo $wf | wc -w | tr -d ' ') workflow(s): $(echo $wf | xargs -n1 basename | paste -sd, -)"
  all=$(cat $wf)
elif [ -f .gitlab-ci.yml ]; then echo "- GitLab CI"; all=$(cat .gitlab-ci.yml)
else gap "no CI configuration found (devops ci templates)"; all=""; fi
if [ -n "$all" ]; then
  chk() { grep -qiE -- "$2" <<<"$all" && echo "- ok: $1" || gap "CI does not run $1"; }
  chk "tests" 'pytest|artisan test|pest|phpunit|vitest|jest|npm (run )?test|pnpm (run )?test|yarn test|go test|cargo test'
  chk "lint/format" 'ruff|pint|eslint|biome|prettier|black|lint'
  chk "type checks" 'mypy|pyright|phpstan|larastan|tsc|typecheck'
  chk "dependency audit" 'composer audit|pip-audit|npm audit|pnpm audit|yarn npm audit|dependency-review'
  chk "secret scan" 'gitleaks|trufflehog'
  grep -qE 'npm install( |$)|yarn install( |$)' <<<"$all" && ! grep -qE 'npm ci|--frozen-lockfile|--immutable' <<<"$all" && gap "non-frozen JS install (use npm ci / --frozen-lockfile)"
  grep -qE 'uv sync' <<<"$all" && ! grep -qE 'uv sync[^\n]*--(frozen|locked)' <<<"$all" && gap "uv sync without --frozen"
  grep -qE 'composer update' <<<"$all" && gap "CI runs composer update (use composer install)"
  unpinned=$(grep -oE 'uses:\s*[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[^ #]+' <<<"$all" | grep -vE 'uses:\s*actions/' | grep -vE '@[0-9a-f]{40}$' | sort -u | wc -l | tr -d ' ')
  [ "$unpinned" -gt 0 ] && gap "$unpinned third-party action(s) not pinned to a commit SHA"
  grep -qE '^\s*permissions:' <<<"$all" || gap "workflows don't set permissions: (default token is broad)"
fi
echo

echo "## Deploy target"
found=""
for f in fly.toml render.yaml vercel.json netlify.toml Procfile app.yaml serverless.yml railway.json docker-compose.prod.yml; do [ -e "$f" ] && found="$found $f"; done
for f in docker-compose*.yml docker-compose*.yaml compose*.yml compose*.yaml; do [ -e "$f" ] && case " $found " in *" $f "*) ;; *) found="$found $f" ;; esac; done
HOSTS='dokploy|coolify|laravel cloud|laravel forge|forge\.laravel\.com'
grep -rliE "$HOSTS" docs README.md 2>/dev/null | head -1 | grep -q . && found="$found (docs mention $(grep -rhoiE "$HOSTS" docs README.md 2>/dev/null | head -1))"
[ -n "$found" ] && echo "- found:$found" || gap "no deploy target config in repo (record hosting in ARCHITECTURE.md §11)"
echo

echo "## Containers"
# Tracked Dockerfiles only (skips worktrees, release snapshots, vendor copies); fall back to find outside git
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dfs=$(git ls-files | grep -E '(^|/)Dockerfile(\.[A-Za-z0-9_-]+)?$' | grep -vE '(^|/)\.[^/]+/|(^|/)(artifacts|releases|dist|build|outputs|node_modules|vendor)/' | sed 's#^#./#' | head -8)
else
  dfs=$(find . -name Dockerfile -not -path '*/node_modules/*' -not -path '*/.*/*' 2>/dev/null | head -8)
fi
if [ -n "$dfs" ]; then
  for d in $dfs; do
    echo "- $d"
    grep -qE '^\s*USER\s' "$d" || gap "$d runs as root (add USER)"
    [ -f "$(dirname "$d")/.dockerignore" ] || gap "$(dirname "$d") has no .dockerignore"
  done
else echo "- no Dockerfile"; fi
echo

echo "## Infrastructure as code"
tf=$(find . -name '*.tf' -not -path './.git/*' -not -path '*/.terraform/*' 2>/dev/null | head -1)
[ -n "$tf" ] && echo "- Terraform/OpenTofu: $(dirname "$tf")" || echo "- none (fine for PaaS; platform config should still be in the repo)"
git ls-files 2>/dev/null | grep -qE '\.tfstate$' && gap "terraform state committed to git"
echo

echo "## Basics"
grep -rqlE "['\"]/(health|healthz|up|ready)['\"]" --include=*.py --include=*.php --include=*.ts --include=*.js . 2>/dev/null && echo "- health endpoint found" || gap "no /health (or /up, /ready) endpoint found"
[ -f docs/ops/DELIVERY.md ] && echo "- docs/ops/DELIVERY.md present" || gap "no docs/ops/DELIVERY.md (delivery-pipeline writes it)"
echo
echo "Result: $gaps gap(s)."
exit 0
