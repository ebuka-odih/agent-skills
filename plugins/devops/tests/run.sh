#!/usr/bin/env bash
# Tests for devops scripts. Usage: bash plugins/devops/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/scripts/infra-guard.sh"; SCAN="$ROOT/scripts/devops-scan.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

g() { local out; out=$(jq -nc --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$GUARD")
      if [ -z "$out" ]; then echo allow; else jq -r .hookSpecificOutput.permissionDecision <<<"$out"; fi; }

echo "infra guard: asks"
for c in "terraform destroy" "cd infra/envs/production && tofu destroy -target=module.db" "terraform apply -auto-approve" \
         "php artisan migrate:fresh --force" "php artisan db:wipe" "php artisan migrate:rollback --step=3" \
         "APP_ENV=production php artisan migrate --force" "alembic downgrade -1" \
         "psql \$DATABASE_URL -c 'DROP TABLE bookings'" "mysql -e 'truncate table users'" "redis-cli FLUSHALL" \
         "docker system prune -a -f" "docker volume rm app_pgdata" "docker compose down -v" \
         "kubectl delete namespace shop" "kubectl --context prod-eu delete deploy api" "kubectl scale deploy api --replicas=0 -n production" \
         "fly apps destroy shop-api" "fly deploy --app shop-production" "vercel --prod" "gh workflow run deploy.yml -f env=production" \
         "ssh deploy@prod-1 'rm -rf /var/www/storage'"; do
  check "ask: $c" '[ "$(g "$c")" = ask ]'
done

echo "infra guard: allows"
for c in "ls -la" "terraform plan -out=tf.plan" "terraform apply tf.plan" "php artisan migrate" "php artisan migrate --force" \
         "php artisan test" "alembic upgrade head" "psql \$DATABASE_URL -c 'select count(*) from bookings'" \
         "docker compose down" "docker system prune -f" "kubectl get pods -n production" "kubectl --context staging delete pod api-123" \
         "fly deploy --app shop-staging" "vercel" "git push origin main" "grep -rn 'migrate:fresh' docs/"; do
  check "allow: $c" '[ "$(g "$c")" = allow ]'
done
reason=$(jq -nc '{tool_name:"Bash", tool_input:{command:"php artisan migrate:fresh --force"}}' | bash "$GUARD" | jq -r .hookSpecificOutput.permissionDecisionReason)
check "reason explains data loss"  'grep -q "drops every table" <<<"$reason"'
off=$(jq -nc '{tool_name:"Bash", tool_input:{command:"terraform destroy"}}' | INFRA_GUARD=off bash "$GUARD")
check "INFRA_GUARD=off disables"   '[ -z "$off" ]'
nonbash=$(jq -nc '{tool_name:"Write", tool_input:{content:"terraform destroy"}}' | bash "$GUARD")
check "non-Bash tool ignored"      '[ -z "$nonbash" ]'

echo "devops scan"
R="$TMP/app"; mkdir -p "$R/.github/workflows" "$R/backend/app"; cd "$R"
cat > .github/workflows/ci.yml <<'EOF'
on: [pull_request]
jobs:
  t:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: npm install
      - run: uv sync
      - run: uv run pytest -q
      - run: uv run ruff check .
EOF
printf 'FROM python:3.12-slim\nCMD ["uvicorn","app.main:app"]\n' > backend/Dockerfile
printf '@app.get("/health")\n' > backend/app/main.py
printf 'services: {}\n' > docker-compose.yml
mkdir -p .muse/worktrees/x artifacts/releases/r; cp backend/Dockerfile .muse/worktrees/x/; cp backend/Dockerfile artifacts/releases/r/
git init -q && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm "chore: init"
out=$(bash "$SCAN" "$R")
check "worktree + release copies ignored" '! grep -qE "\.muse|artifacts/releases" <<<"$out"'
check "detects GitHub Actions"          'grep -q "GitHub Actions: 1 workflow" <<<"$out"'
check "tests + lint ok"                 'grep -q "ok: tests" <<<"$out" && grep -q "ok: lint/format" <<<"$out"'
check "missing types/audit/secret scan" 'grep -q "CI does not run type checks" <<<"$out" && grep -q "CI does not run dependency audit" <<<"$out" && grep -q "CI does not run secret scan" <<<"$out"'
check "non-frozen npm + uv"             'grep -q "non-frozen JS install" <<<"$out" && grep -q "uv sync without --frozen" <<<"$out"'
check "unpinned third-party action"     'grep -q "1 third-party action(s) not pinned" <<<"$out"'
check "permissions missing"             'grep -q "don.t set permissions" <<<"$out"'
check "compose as deploy target"        'grep -q "found:.*docker-compose.yml" <<<"$out"'
check "Dockerfile root + no dockerignore" 'grep -q "runs as root" <<<"$out" && grep -q "has no .dockerignore" <<<"$out"'
check "health endpoint found"           'grep -q "health endpoint found" <<<"$out"'
check "DELIVERY.md missing"             'grep -q "no docs/ops/DELIVERY.md" <<<"$out"'
E="$TMP/empty"; mkdir -p "$E"; out=$(bash "$SCAN" "$E")
check "empty repo: no CI gap"           'grep -q "no CI configuration found" <<<"$out"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
