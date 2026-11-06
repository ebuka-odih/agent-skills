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

echo "uptime-scan"
UP="$ROOT/scripts/uptime-scan.sh"
us() { bash "$UP" "$@" 2>&1; }
U="$TMP/up1"; mkdir -p "$U/web" "$U/app"
cat > "$U/web/nginx.conf" <<'N'
server {
  location / { try_files $uri $uri/ /index.html; }
  location /api { proxy_pass http://backend; proxy_intercept_errors on; error_page 500 502 503 504 = @spa; }
  location @spa {
    try_files /index.html =404;
  }
  location /old { error_page 502 =200 /ok.html; }
  # error_page 502 =200 /commented.html;
}
N
printf 'from fastapi import FastAPI\napp = FastAPI()\n' > "$U/app/main.py"
printf 'FROM python:3.12-slim\nCMD ["uvicorn", "app.main:app"]\n' > "$U/Dockerfile"
printf 'services:\n  web:\n    build: .\n' > "$U/compose.yaml"
out=$(us "$U")
check "U1: 5xx → @spa serving index.html"   'grep -q "error web/nginx.conf:3 U1: 5xx from the upstream is answered by @spa" <<<"$out"'
check "U1: =200 on 5xx"                      'grep -q "error web/nginx.conf:7 U1: error_page turns server errors into 200" <<<"$out"'
check "U1: comments ignored"                 '! grep -q "nginx.conf:8 " <<<"$out"'
check "U2: SPA fallback soft 404"            'grep -q "warn web/nginx.conf:2 U2" <<<"$out"'
check "U2: =404 fallback is fine"            '! grep -q "nginx.conf:5 U2" <<<"$out"'
check "U3: FastAPI without health route"     'grep -q "warn app U3" <<<"$out"'
check "U4: no HEALTHCHECK anywhere"          'grep -q "warn Dockerfile U4" <<<"$out"'
check "U5: compose without restart"          'grep -q "warn compose.yaml U5" <<<"$out"'
check "U6: uvicorn without graceful timeout" 'grep -q "info Dockerfile:2 U6" <<<"$out"'
check "summary counts"                       'grep -q "Result: 2 error(s), 4 warning(s), 1 info." <<<"$out"'
check "--strict fails on errors"             '! bash "$UP" "$U" --strict >/dev/null'
G="$TMP/up2"; mkdir -p "$G/web" "$G/app"
cat > "$G/web/nginx.conf" <<'N'
server {
  location / { try_files $uri $uri/ =404; }
  location @app { proxy_pass http://backend; proxy_intercept_errors on; error_page 502 503 504 =503 @down; }
  location @down { add_header Retry-After 120 always; try_files /app.html =503; }
  location @err { error_page 500 = @maint; }
  location @maint { return 503; }
}
N
printf 'from fastapi import FastAPI\napp = FastAPI()\n@app.get("/livez")\ndef livez():\n    return {}\n' > "$G/app/main.py"
printf 'FROM python:3.12-slim\nHEALTHCHECK CMD curl -fsS http://localhost:8000/livez || exit 1\nCMD ["uvicorn", "app.main:app", "--timeout-graceful-shutdown", "20"]\n' > "$G/Dockerfile"
printf 'services:\n  web:\n    build: .\n    restart: unless-stopped\n' > "$G/compose.yaml"
out=$(us "$G")
check "correct stack is clean"               'grep -q "Result: 0 error(s), 0 warning(s), 0 info." <<<"$out"'
check "--strict passes when clean"           'bash "$UP" "$G" --strict >/dev/null'
L="$TMP/up3"; mkdir -p "$L/routes" "$L/bootstrap"
printf '<?php\nuse Illuminate\\Foundation\\Application;\nreturn Application::configure()->withRouting(web: "routes/web.php", health: "/up");\n' > "$L/bootstrap/app.php"
printf 'FROM php:8.3\n' > "$L/Dockerfile"; printf 'services:\n  app:\n    healthcheck:\n      test: ["CMD", "curl", "-f", "http://localhost/up"]\n    restart: always\n' > "$L/docker-compose.yml"
out=$(us "$L")
check "Laravel health: /up counts"           '! grep -q U3 <<<"$out"'
check "compose healthcheck counts for U4"    '! grep -q U4 <<<"$out"'
N0="$TMP/up4"; mkdir -p "$N0/src"; printf 'export const x = 1\n' > "$N0/src/a.ts"
check "non-server code: no U3"               '! us "$N0" | grep -q U3'
mkdir -p "$G/tests/web"; printf 'server { location / { try_files $uri /index.html; } }\n' > "$G/tests/web/nginx.conf"
check "test fixtures ignored"                '! us "$G" | grep -q U2'
check "missing dir: exit 2"                  'bash "$UP" "$TMP/none" >/dev/null; [ $? = 2 ]'
upsrv() { local pf="$TMP/upport.$1"; python3 "$ROOT/tests/fixtures/uptime_server.py" "$pf" "$1" & SP=$!; for _ in $(seq 1 50); do [ -s "$pf" ] && break; sleep 0.1; done; SU="http://127.0.0.1:$(cat "$pf")"; }
upsrv good; out=$(us "$G" --url "$SU"); kill $SP; wait $SP 2>/dev/null
check "live: 404 for unknown URL is good"    'grep -q "live: unknown URL → 404 (good)" <<<"$out"'
check "live: finds /livez"                   'grep -q "live: health endpoint /livez → 200" <<<"$out" && grep -q "Result: 0 error(s), 0 warning(s)" <<<"$out"'
upsrv soft; out=$(us "$G" --url "$SU"); kill $SP; wait $SP 2>/dev/null
check "live: soft 404 warned"                'grep -q "U7: unknown URL returns 200, not 404" <<<"$out"'
upsrv nohealth; out=$(us "$G" --url "$SU/"); kill $SP; wait $SP 2>/dev/null
check "live: no health endpoint warned"      'grep -q "U8: no public health endpoint answered 200" <<<"$out"'
check "live: trailing slash on --url ok"     'grep -q "unknown URL → 404" <<<"$out"'
upsrv slow; out=$(us "$G" --url "$SU"); kill $SP; wait $SP 2>/dev/null
check "live: slow health endpoint warned"    'grep -q "U8: health endpoint took 1\.[0-9]*s" <<<"$out"'
out=$(us "$G" --url "http://127.0.0.1:9")
check "live: no answer is an error"          'grep -q "error http://127.0.0.1:9 U7: site did not answer" <<<"$out"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
