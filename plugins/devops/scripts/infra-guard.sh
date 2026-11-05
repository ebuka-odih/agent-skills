#!/usr/bin/env bash
# PreToolUse(Bash) hook: make destructive infrastructure / production commands ASK first.
# Never denies outright — a human decides. Normal commands pass silently.
set -u
trap 'exit 0' ERR
exec 2>/dev/null
command -v jq >/dev/null 2>&1 || exit 0
[ "${INFRA_GUARD:-on}" = "off" ] && exit 0

input="$(cat)"
[ "$(jq -r '.tool_name // empty' <<<"$input")" = "Bash" ] || exit 0
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

ask() {
  jq -nc --arg r "devops: $1 Confirm only if you meant it (backup taken, right environment, rollback known). See devops release-and-rollback." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"ask", permissionDecisionReason:$r}}'
  exit 0
}
has() { grep -qiE -- "$1" <<<"$cmd"; }
prod='(prod|production)([^a-z]|$)'

# Infrastructure as code
has '(terraform|tofu)\s+([^;&|]*\s)?destroy' && ask "this destroys infrastructure (terraform/tofu destroy)."
has '(terraform|tofu)\s+apply\b[^;&|]*-auto-approve' && ask "terraform/tofu apply with -auto-approve skips plan review."
# Database: destructive resets and drops
has 'artisan\s+(migrate:fresh|migrate:reset|db:wipe)' && ask "this drops every table and its data (artisan migrate:fresh/reset/db:wipe)."
has 'artisan\s+migrate:rollback' && ask "migrate:rollback reverses migrations and can drop columns with data."
has 'artisan\s+migrate\b[^;&|]*--force' && has "$prod|APP_ENV=prod" && ask "this runs migrations against production."
has 'alembic\s+downgrade' && ask "alembic downgrade reverses migrations and can drop data."
has '(psql|mysql|mariadb|sqlite3|mongosh|redis-cli)\b' && has '\b(drop\s+(database|schema|table)|truncate\s|flushall|flushdb|dropDatabase)' && ask "this runs a destructive database statement (DROP/TRUNCATE/FLUSH)."
# Containers and volumes
has 'docker\s+(system|volume|image)\s+prune\b[^;&|]*(-a|--all|--volumes)' && ask "docker prune with --all/--volumes deletes images or data volumes."
has 'docker\s+volume\s+rm\b' && ask "docker volume rm deletes the data in that volume."
has 'docker[- ]compose\b[^;&|]*\bdown\b[^;&|]*(\s-v\b|--volumes)' && ask "compose down -v deletes the project's data volumes."
# Kubernetes
has 'kubectl\b[^;&|]*\sdelete\s+(ns|namespace)\b' && ask "kubectl delete namespace removes everything in it."
has 'kubectl\b[^;&|]*\s(delete|drain|scale)\b' && has "$prod|--context[= ]\S*prod" && ask "this changes production workloads (kubectl delete/drain/scale)."
# Platform destroy / production deploys
has '(fly|flyctl)\s+(apps\s+)?destroy|heroku\s+apps:destroy|vercel\s+(remove|rm)\b|render\s+.*delete' && ask "this deletes an app on the hosting platform."
has '(fly|flyctl)\s+deploy\b' && has "$prod" && ask "this deploys to production."
has 'vercel\b[^;&|]*--prod\b' && ask "this deploys to production (vercel --prod)."
has 'gh\s+workflow\s+run\b' && has "$prod" && ask "this triggers a production workflow."
# Production shells
has '\bssh\b[^;&|]*'"$prod" && has '(rm\s+-rf|migrate|drop|truncate|systemctl\s+(stop|restart))' && ask "this runs a destructive command on a production host."
exit 0
