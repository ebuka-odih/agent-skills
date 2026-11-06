#!/usr/bin/env bash
# Backend risk rules. Sourced by backend-scan.sh and backend-hook.sh.
# be_scan_file <path-to-report> <file-on-disk>  → lines "severity path:line rule: message"
# Severities: error (breaks prod / data), warn (risky; check it), info (worth a look).

be_kind() { # classify a path
  case "$1" in
    node_modules/*|*/node_modules/*|vendor/*|*/vendor/*|.venv/*|*/.venv/*|venv/*|*/venv/*|*/site-packages/*|dist/*|*/dist/*|build/*|*/build/*) echo skip ;;
    *database/migrations/*.php|*migrations/versions/*.py|*alembic/versions/*.py|*migrations/*.sql|migrations/*.py|*/migrations/*.py|*migrations/*.ts|*migrations/*.js) echo migration ;;
    *test*|*/fixtures/*|*/spec/*) echo skip ;;
    *app/Jobs/*.php) echo laravel-job ;;
    *.php) echo php ;;
    *.py) echo python ;;
    *) echo other ;;
  esac
}

be_scan_file() {
  local p="$1" f="$2" kind; kind=$(be_kind "$p")
  [ -f "$f" ] || return 0
  case "$kind" in
    migration)
      # two passes: pass 1 joins the file to find tables created here (names may sit on the next line);
      # pass 2 checks line by line, looking 2 lines ahead for the table an index is on.
      awk -v path="$p" '
        FNR == NR { L[FNR] = $0; all = all " " $0; n = FNR; next }
        FNR == 1 {
          s = all
          while (match(s, /create_table\([[:space:]]*["\047][A-Za-z0-9_]+/)) { t = substr(s, RSTART, RLENGTH); sub(/.*["\047]/, "", t); created[t] = 1; s = substr(s, RSTART + RLENGTH) }
          s = all
          while (match(s, /CREATE TABLE (IF NOT EXISTS )?["]?[A-Za-z0-9_]+/)) { t = substr(s, RSTART, RLENGTH); sub(/.* ["]?/, "", t); created[t] = 1; s = substr(s, RSTART + RLENGTH) }
          s = all
          while (match(s, /Schema::create\([[:space:]]*["\047][A-Za-z0-9_]+/)) { t = substr(s, RSTART, RLENGTH); sub(/.*["\047]/, "", t); created[t] = 1; s = substr(s, RSTART + RLENGTH) }
          alter = 0; down = 0
        }
        /Schema::table\(/ { alter = 1 } /Schema::create\(/ { alter = 0 }
        /^def downgrade|function down\(/ { down = 1 } /^def upgrade|function up\(/ { down = 0 }
        down { next }
        {
          l = $0; w = l " " L[FNR + 1] " " L[FNR + 2]; ix = ""
          if (match(w, /create_index\([^,]*,[[:space:]]*["\047][A-Za-z0-9_]+/)) { ix = substr(w, RSTART, RLENGTH); sub(/.*["\047]/, "", ix) }
          if (l ~ /CREATE (UNIQUE )?INDEX/ && match(w, /[[:space:]"\047]ON[[:space:]]+["]?[A-Za-z0-9_]+/)) { ix = substr(w, RSTART, RLENGTH); sub(/.*ON[[:space:]]+["]?/, "", ix) }
          isnew = (ix != "" && (ix in created))
        }
        { if (l ~ /dropColumn\(|drop_column\(|DROP COLUMN|dropIfExists\(|drop_table\(|DROP TABLE/) print "warn " path ":" FNR " M1: drops a column/table — only after a deploy where no running code reads it" }
        { if (l ~ /renameColumn\(|rename_column|new_column_name=|RENAME COLUMN|Schema::rename\(|rename_table\(|RENAME TO/) print "error " path ":" FNR " M2: rename breaks running code — add new, dual-write, backfill, switch, then drop old" }
        { if (l ~ /->change\(\)|alter_column\(.*type_=|ALTER COLUMN [^ ]+ (SET DATA )?TYPE/) print "warn " path ":" FNR " M3: column type change rewrites/locks the table — new column + backfill + switch" }
        { if (l ~ /add_column\(.*nullable=False/ && l !~ /server_default/) print "error " path ":" FNR " M4: NOT NULL column without server_default fails on existing rows — add nullable, backfill, then constrain" }
        { if (l ~ /ADD COLUMN/ && l ~ /NOT NULL/ && l !~ /DEFAULT/) print "error " path ":" FNR " M4: NOT NULL column without DEFAULT fails on existing rows — add nullable, backfill, then constrain" }
        { if (alter && l ~ /\$table->(string|text|integer|bigInteger|boolean|date|dateTime|timestamp|decimal|json|uuid|foreignId|unsignedBigInteger)\(/ && l !~ /nullable\(|default\(|->change\(\)/) print "error " path ":" FNR " M4: new column on an existing table is NOT NULL by default in Laravel — add ->nullable() (backfill later) or ->default()" }
        { if (l ~ /create_index\(/ && l !~ /postgresql_concurrently/ && !isnew) print "warn " path ":" FNR " M5: index on an existing table built with a write lock — on big Postgres tables use postgresql_concurrently=True in an autocommit_block" }
        { if (l ~ /CREATE (UNIQUE )?INDEX/ && l !~ /CONCURRENTLY/ && !isnew) print "warn " path ":" FNR " M5: index on an existing table built with a write lock — CREATE INDEX CONCURRENTLY on big tables" }
        { if (alter && l ~ /->(index|unique)\(/) print "warn " path ":" FNR " M5: index on an existing table locks writes — on big Postgres tables use CREATE INDEX CONCURRENTLY with $withinTransaction = false" }
        { if (l ~ /SET NOT NULL|alter_column\(.*nullable=False/) print "warn " path ":" FNR " M6: SET NOT NULL scans the table under lock — CHECK (col IS NOT NULL) NOT VALID, VALIDATE, then SET NOT NULL" }
      ' "$f" "$f" ;;
    laravel-job)
      grep -q 'ShouldQueue' "$f" || return 0
      awk -v path="$p" '
        /\$tries|retryUntil\(/ { tries = 1 } /\$timeout/ { timeout = 1 } /\$backoff|function backoff\(/ { backoff = 1 } /function failed\(/ { failed = 1 } /class [A-Za-z_]+/ && !cls { cls = NR }
        END {
          if (!tries) print "warn " path ":" cls " J1: queued job without $tries or retryUntil() — unbounded retries"
          if (!timeout) print "warn " path ":" cls " J2: queued job without $timeout — keep it below the queue retry_after or it runs twice"
          if (!backoff) print "warn " path ":" cls " J3: queued job without $backoff — retries fire immediately (retry storm)"
          if (!failed) print "info " path ":" cls " J4: no failed() handler — record why and alert after the last attempt"
        }' "$f" ;;
    python)
      awk -v path="$p" '
        /^[[:space:]]*async def / { has_async = 1 }
        /threading\.Thread\(/ { thread = NR } /asyncio\.run\(|new_event_loop\(/ { loop = NR }
        /autoretry_for/ && !/retry_backoff/ { print "warn " path ":" NR " J3: Celery autoretry without retry_backoff — failures retry immediately" }
        /cron_jobs[[:space:]]*=/ { cron = NR }
        /^[[:space:]]*if (not )?\(?(await )?[A-Za-z_.]*(taken|exists?|existing|already|duplicate|found)[A-Za-z_]*/ { chk = NR }
        { if (chk && NR > chk && NR - chk <= 6 && $0 ~ /\.add\(|\.create\(|insert\(|INSERT INTO/) { c1[++n1] = chk; chk = 0 } }
        /ON CONFLICT|on_conflict_do|IntegrityError|UniqueViolation/ { uniq_guard = 1 }
        { if ($0 ~ /\.(balance|stock|credits|quantity|quota|remaining|available|seats|inventory)[[:space:]]*[-+]=/) c2[++n2] = NR }
        /with_for_update|FOR UPDATE|advisory_lock|_lock_[a-z_]*\(/ { row_lock = 1 }
        /while True:/ { wt = NR; poll = 0 }
        { if (wt && NR > wt && NR - wt <= 25 && $0 ~ /sleep\(/) poll = 1 }
        /signal\.|stop_event|_stop|stopping|should_stop|is_set\(|CancelledError|shutdown|\.cancel\(/ { stopper = 1 }
        {
          if ($0 ~ /requests\.(get|post|put|patch|delete|head|request)\(/) { call = NR; buf = $0; open = 1 }
          else if (open && NR - call <= 4) buf = buf $0
          if (open && (buf ~ /\)[[:space:]]*$/ || NR - call >= 4)) { if (buf !~ /timeout[[:space:]]*=/) print "error " path ":" call " O1: requests call without timeout= — it can hang forever"; open = 0 }
        }
        { if (has_async && $0 ~ /time\.sleep\(/) print "warn " path ":" NR " J5: time.sleep in async code blocks the event loop — await asyncio.sleep" }
        END {
          if (thread && loop) print "warn " path ":" thread " J6: thread running its own event loop — it must not use the app'"'"'s async engine/pool/clients (they hang on another loop); run it as an asyncio task on the app loop or give it its own engine"
          oneoff = (path ~ /(^|\/)(scripts|tools|seeds?|maintenance)\// || path ~ /seed[^\/]*\.py$/) ? "info " : "warn "   # one-off scripts: worth a look, not a gate
          if (!uniq_guard) for (i = 1; i <= n1; i++) print oneoff path ":" c1[i] " C1: check-then-insert — two requests can both pass the check; add a unique constraint and catch the violation (or ON CONFLICT)"
          if (!row_lock) for (i = 1; i <= n2; i++) print "warn " path ":" c2[i] " C2: read-modify-write on a counter — concurrent updates are lost; use one atomic UPDATE … SET x = x - :n WHERE x >= :n (or lock the row first)"
          if (wt && poll && !stopper) print oneoff path ":" wt " G1: polling loop (while True + sleep) with no stop condition — SIGTERM kills it mid-job; check a stop flag/event before each unit of work"
          if (cron) print "info " path ":" cron " S2: arq cron_jobs only fire in a deployed arq worker — check the deploy config (be_scan_repo reports it)"
        }' "$f" ;;
    php)
      awk -v path="$p" '
        { if ($0 ~ /(Schedule::|\$schedule->)(job|command|call|exec)\(/ && $0 !~ /withoutOverlapping/) print "warn " path ":" NR " S1: scheduled task without ->withoutOverlapping() — a slow run overlaps the next" }
        /->exists\(\)|->first\(\)|->count\(\)/ && /if[[:space:]]*\(/ { chk = NR }
        { if (chk && NR > chk && NR - chk <= 6 && $0 ~ /::create\(|->save\(\)|->insert\(/) { c1[++n1] = chk; chk = 0 } }
        /UniqueConstraintViolation|QueryException|upsert\(|insertOrIgnore\(|firstOrCreate\(|updateOrCreate\(/ { uniq_guard = 1 }
        { if ($0 ~ /->(balance|stock|credits|quantity|quota|remaining|available|seats|inventory)[[:space:]]*[-+]=/) c2[++n2] = NR }
        /lockForUpdate\(|sharedLock\(|Cache::lock\(/ { row_lock = 1 }
        END {
          if (!uniq_guard) for (i = 1; i <= n1; i++) print "warn " path ":" c1[i] " C1: check-then-insert — two requests can both pass the check; add a unique index and catch UniqueConstraintViolationException (or upsert)"
          if (!row_lock) for (i = 1; i <= n2; i++) print "warn " path ":" c2[i] " C2: read-modify-write on a counter — use ->decrement()/->increment() with a where guard, or lockForUpdate() in a transaction"
        }
      ' "$f" ;;
  esac
}

# be_scan_repo <dir> — cross-file checks (schedulers vs what is deployed)
be_scan_repo() {
  local d="$1" deploy
  deploy=$(find "$d" -maxdepth 3 \( -name 'Dockerfile*' -o -name '*compose*.y*ml' -o -name 'Procfile' -o -name 'fly.toml' -o -name '*.service' -o -name 'supervisord*.conf' \) -not -path '*/node_modules/*' 2>/dev/null)
  local arqcron; arqcron=$(grep -rlE 'cron_jobs[[:space:]]*=' --include='*.py' "$d" 2>/dev/null | grep -vE '/(\.venv|venv|site-packages|node_modules)/' | head -1)
  if [ -n "$arqcron" ] && ! { [ -n "$deploy" ] && grep -lE '(^|[^a-z])arq[[:space:]]' $deploy >/dev/null 2>&1; }; then
    echo "error ${arqcron#"$d"/}:1 S2: arq cron_jobs defined but no deploy file starts an arq worker — these jobs never run"
  fi
  local c
  for c in $(find "$d" -maxdepth 3 -name '*compose*.y*ml' -not -path '*/node_modules/*' 2>/dev/null); do
    awk -v path="${c#"$d"/}" '
      /^  [A-Za-z0-9_.-]+:[[:space:]]*$/ { if (svc != "" && worker && !grace) print "warn " path ":" line " G2: worker service \"" svc "\" has no stop_grace_period — Docker kills it after 10 s, mid-job"; svc = $1; sub(/:$/, "", svc); line = NR; worker = 0; grace = 0 }
      /command:|entrypoint:/ && /(worker|queue:work|horizon|arq |celery|rq worker|dramatiq)/ { worker = 1 }
      /stop_grace_period:/ { grace = 1 }
      END { if (svc != "" && worker && !grace) print "warn " path ":" line " G2: worker service \"" svc "\" has no stop_grace_period — Docker kills it after 10 s, mid-job" }
    ' "$c"
  done
  local beat; beat=$(grep -rlE 'beat_schedule' --include='*.py' "$d" 2>/dev/null | grep -vE '/(\.venv|venv|site-packages)/' | head -1)
  if [ -n "$beat" ] && ! { [ -n "$deploy" ] && grep -lE 'celery.*beat' $deploy >/dev/null 2>&1; }; then
    echo "error ${beat#"$d"/}:1 S3: Celery beat_schedule defined but no deploy file runs celery beat — these tasks never run"
  fi
  return 0
}
