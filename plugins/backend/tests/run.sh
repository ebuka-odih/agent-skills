#!/usr/bin/env bash
# Tests for backend scripts. Usage: bash plugins/backend/tests/run.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN="$ROOT/scripts/backend-scan.sh"; HOOK="$ROOT/scripts/backend-hook.sh"
. "$ROOT/scripts/backend-patterns.sh"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
has()  { grep -qF -- "$2" <<<"$1"; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# s <path> <content> → findings for that file
s() { mkdir -p "$TMP/$(dirname "$1")"; printf '%s\n' "$2" > "$TMP/$1"; be_scan_file "$1" "$TMP/$1"; }

echo "classification"
check "laravel migration"          '[ "$(be_kind database/migrations/2026_01_01_x.php)" = migration ]'
check "alembic at repo root"       '[ "$(be_kind alembic/versions/001_x.py)" = migration ]'
check "nested alembic"             '[ "$(be_kind backend/alembic/versions/001_x.py)" = migration ]'
check "sql migration"              '[ "$(be_kind db/migrations/0001.sql)" = migration ]'
check "laravel job"                '[ "$(be_kind app/Jobs/SendInvoice.php)" = laravel-job ]'
check "tests skipped"              '[ "$(be_kind tests/test_jobs.py)" = skip ] && [ "$(be_kind app/fixtures/x.py)" = skip ]'
check "vendored code skipped"      '[ "$(be_kind backend/.venv/lib/x.py)" = skip ] && [ "$(be_kind vendor/a/b.php)" = skip ]'
check "python / php / other"       '[ "$(be_kind app/x.py)" = python ] && [ "$(be_kind app/Http/C.php)" = php ] && [ "$(be_kind web/a.tsx)" = other ]'

echo "migrations (alembic)"
o=$(s alembic/versions/1.py 'def upgrade():
    op.add_column("t", sa.Column("x", sa.String(), nullable=False))
    op.add_column("t", sa.Column("y", sa.String(), nullable=False, server_default="a"))
    op.alter_column("t", "z", new_column_name="zz")
    op.alter_column("t", "n", type_=sa.BigInteger())
    op.drop_column("t", "old")
    op.create_index("t_x", "t", ["x"])
    op.alter_column("t", "x", nullable=False)
def downgrade():
    op.drop_column("t", "x")
    op.create_index("t_y", "t", ["y"])')
check "M4 NOT NULL without default"   'has "$o" "error alembic/versions/1.py:2 M4"'
check "M4 skips server_default"       '! has "$o" ":3 M4"'
check "M2 rename is an error"         'has "$o" "error alembic/versions/1.py:4 M2"'
check "M3 type change"                'has "$o" "warn alembic/versions/1.py:5 M3"'
check "M1 drop column"                'has "$o" "warn alembic/versions/1.py:6 M1"'
check "M5 index on existing table"    'has "$o" "warn alembic/versions/1.py:7 M5"'
check "M6 set not null"               'has "$o" "warn alembic/versions/1.py:8 M6"'
check "downgrade() is not flagged"    '! has "$o" ":10 " && ! has "$o" ":11 "'
o=$(s alembic/versions/2.py 'def upgrade():
    op.create_table(
        "jobs",
        sa.Column("id", sa.Integer()))
    op.create_index("jobs_q", "jobs", ["q"])
    op.execute(
        "CREATE INDEX IF NOT EXISTS jobs_ready "
        "ON jobs (queue)")
    op.execute("CREATE INDEX places_x ON places (x)")
    with op.get_context().autocommit_block():
        op.create_index("places_y", "places", ["y"], postgresql_concurrently=True)
    op.execute("CREATE INDEX CONCURRENTLY places_z ON places (z)")')
check "index on table created here: ok"     '! has "$o" ":5 M5" && ! has "$o" ":7 M5"'
check "SQL index on existing table: M5"     'has "$o" "warn alembic/versions/2.py:9 M5"'
check "concurrent indexes: ok"              '! has "$o" ":11 " && ! has "$o" ":12 "'
o=$(s db/migrations/3.sql 'CREATE TABLE "orders" (id int);
CREATE INDEX orders_x ON "orders" (x);
ALTER TABLE users ADD COLUMN plan text NOT NULL;
ALTER TABLE users ADD COLUMN tier text NOT NULL DEFAULT '"'"'free'"'"';
ALTER TABLE users RENAME COLUMN a TO b;
ALTER TABLE users ALTER COLUMN age TYPE bigint;
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
DROP TABLE legacy;')
check "SQL: quoted new table index ok"      '! has "$o" ":2 M5"'
check "SQL: NOT NULL without DEFAULT"       'has "$o" "error db/migrations/3.sql:3 M4" && ! has "$o" ":4 M4"'
check "SQL: rename / type / set not null / drop" 'has "$o" ":5 M2" && has "$o" ":6 M3" && has "$o" ":7 M6" && has "$o" ":8 M1"'

echo "migrations (laravel)"
o=$(s database/migrations/2026_x.php '<?php
return new class extends Migration {
  public function up(): void {
    Schema::create("bookings", function (Blueprint $table) {
      $table->string("name");
      $table->index("name");
    });
    Schema::table("users", function (Blueprint $table) {
      $table->string("phone");
      $table->string("nick")->nullable();
      $table->boolean("vip")->default(false);
      $table->index("phone");
      $table->renameColumn("a", "b");
      $table->dropColumn("c");
      $table->string("bio", 500)->change();
    });
  }
  public function down(): void {
    Schema::table("users", function (Blueprint $table) { $table->dropColumn("phone"); });
    Schema::dropIfExists("bookings");
  }
};')
check "create(): NOT NULL + index fine"     '! has "$o" ":5 " && ! has "$o" ":6 "'
check "table(): NOT NULL column error"      'has "$o" "error database/migrations/2026_x.php:9 M4"'
check "table(): nullable / default fine"    '! has "$o" ":10 " && ! has "$o" ":11 "'
check "table(): index warn"                 'has "$o" ":12 M5"'
check "rename / drop / change"              'has "$o" ":13 M2" && has "$o" ":14 M1" && has "$o" ":15 M3"'
check "down() ignored"                      '! has "$o" ":19 " && ! has "$o" ":20 "'

echo "jobs and schedulers"
o=$(s app/Jobs/Bare.php '<?php
class Bare implements ShouldQueue {
  public function handle(): void {}
}')
check "job without tries/timeout/backoff"   'has "$o" "warn app/Jobs/Bare.php:2 J1" && has "$o" ":2 J2" && has "$o" ":2 J3" && has "$o" "info app/Jobs/Bare.php:2 J4"'
o=$(s app/Jobs/Good.php '<?php
class Good implements ShouldQueue {
  public $tries = 3; public $timeout = 60; public $backoff = [10, 60];
  public function failed(Throwable $e): void {}
}')
check "complete job is clean"               '[ -z "$o" ]'
o=$(s app/Jobs/Until.php '<?php
class Until implements ShouldQueue { public $timeout = 30; public function retryUntil() {} public function backoff() { return [5]; } public function failed() {} }')
check "retryUntil()/backoff() count"        '[ -z "$o" ]'
o=$(s app/Jobs/Helper.php '<?php class Helper { }')
check "non-queued class in Jobs ignored"    '[ -z "$o" ]'
o=$(s routes/console.php '<?php
Schedule::job(new Sync)->everyMinute();
Schedule::command("x")->hourly()->withoutOverlapping();
$schedule->call(fn () => 1)->daily();')
check "schedule without overlap guard"      'has "$o" "warn routes/console.php:2 S1" && has "$o" ":4 S1" && ! has "$o" ":3 "'

echo "python"
o=$(s app/svc.py 'import requests, time, threading, asyncio
r = requests.get(url)
r = requests.post(url, json=x, timeout=10)
r = requests.get(
    url,
    headers=h,
    timeout=(3, 10),
)
r = requests.request("GET", url,
    headers=h)
def sync(): time.sleep(1)')
check "requests without timeout"            'has "$o" "error app/svc.py:2 O1" && has "$o" "error app/svc.py:9 O1"'
check "requests with timeout (multi-line)"  '! has "$o" ":3 O1" && ! has "$o" ":4 O1"'
check "time.sleep in sync-only file ok"     '! has "$o" "J5"'
o=$(s app/worker.py 'import asyncio, threading, time
class W:
    def start(self):
        self.t = threading.Thread(target=self.run, daemon=True)
    def run(self):
        asyncio.run(self.cycle())
    async def cycle(self):
        time.sleep(2)')
check "thread + own loop = J6"              'has "$o" "warn app/worker.py:4 J6"'
check "time.sleep in async file = J5"       'has "$o" "warn app/worker.py:8 J5"'
o=$(s app/only_thread.py 'import threading
threading.Thread(target=f).start()')
check "thread alone is fine"                '[ -z "$o" ]'
o=$(s app/tasks.py '@app.task(autoretry_for=(Exception,))
def a(): pass
@app.task(autoretry_for=(Exception,), retry_backoff=True)
def b(): pass
cron_jobs = [cron(x)]')
check "celery autoretry without backoff"    'has "$o" "warn app/tasks.py:1 J3" && ! has "$o" ":3 J3"'
check "arq cron noted"                      'has "$o" "info app/tasks.py:5 S2"'

echo "repo checks (scheduler vs deploy)"
R="$TMP/repo"; mkdir -p "$R/app"; echo 'cron_jobs = [cron(send)]' > "$R/app/arq_worker.py"; echo 'CMD ["uvicorn", "app.main:app"]' > "$R/Dockerfile"
o=$(be_scan_repo "$R")
check "arq cron without deployed worker"    'has "$o" "error app/arq_worker.py:1 S2"'
printf 'services:\n  worker:\n    command: arq app.arq_worker.WorkerSettings\n    stop_grace_period: 60s\n' > "$R/compose.yaml"
check "deployed arq worker → ok"            '[ -z "$(be_scan_repo "$R")" ]'
R2="$TMP/repo2"; mkdir -p "$R2"; echo 'beat_schedule = {}' > "$R2/celery_app.py"
check "celery beat without deploy"          'has "$(be_scan_repo "$R2")" "S3"'
printf 'web: gunicorn app\nbeat: celery -A app beat\n' > "$R2/Procfile"
check "deployed beat → ok"                  '[ -z "$(be_scan_repo "$R2")" ]'

echo "concurrency (C1, C2)"
o=$(s app/book.py 'async def book(db, slot):
    taken = await db.scalar(select(B).where(B.slot == slot))
    if taken:
        raise Conflict()
    db.add(B(slot=slot))
def spend(user, n):
    user.credits -= n
def fine(user, n):
    user.name = "x"')
check "C1: check then add"                   'has "$o" "warn app/book.py:3 C1"'
check "C2: counter -= in python"             'has "$o" "warn app/book.py:7 C2"'
o=$(s app/book2.py 'async def book(db, slot):
    existing = await db.scalar(q)
    if existing:
        return existing
    db.execute(text("INSERT INTO b VALUES (:s) ON CONFLICT DO NOTHING"))')
check "C1: ON CONFLICT in file → fine"       '! has "$o" "C1"'
o=$(s app/book3.py 'def book(db, slot):
    if exists(slot):
        raise X
    for i in range(20): pass
    for i in range(20): pass
    for i in range(20): pass
    for i in range(20): pass
    for i in range(20): pass
    db.add(B())')
check "C1: insert far from check ignored"    '! has "$o" "C1"'
o=$(s app/charge.py 'def charge(db, uid, n):
    user = _lock_user(db, uid)
    user.credits -= n')
check "C2: row lock in file → fine"          '! has "$o" "C2"'
o=$(s app/Http/Wallet.php '<?php
class Wallet { function pay($u, $n) {
  if (Payment::where("ref", $r)->exists()) { return; }
  Payment::create(["ref" => $r]);
  $u->balance -= $n; $u->save();
} }')
check "C1/C2 in PHP"                          'has "$o" "warn app/Http/Wallet.php:3 C1" && has "$o" "warn app/Http/Wallet.php:5 C2"'
o=$(s app/Http/Wallet2.php '<?php
class W { function pay($u) {
  if (P::where("r", 1)->exists()) { return; }
  P::firstOrCreate(["r" => 1]);
  DB::transaction(fn () => U::lockForUpdate()->find(1)); $u->balance -= 1;
} }')
check "PHP guards suppress C1/C2"             '! has "$o" "C1" && ! has "$o" "C2"'

o=$(s app/tools/seed_market.py 'def seed(db):
    if exists(x):
        return
    db.add(X())
import time
while True:
    time.sleep(1)')
check "one-off scripts: C1/G1 as info"        'has "$o" "info app/tools/seed_market.py:2 C1" && has "$o" "info app/tools/seed_market.py:6 G1"'
echo "graceful shutdown (G1, G2)"
o=$(s app/poller.py 'import time
def run():
    while True:
        work()
        time.sleep(5)')
check "G1: polling loop without stop"         'has "$o" "warn app/poller.py:3 G1"'
o=$(s app/pager.py 'def all_pages(c):
    while True:
        page = c.next()
        if not page:
            break')
check "G1: loop without sleep (pagination)"   '! has "$o" "G1"'
o=$(s app/poller2.py 'import asyncio
stop = asyncio.Event()
async def run():
    while True:
        if stop.is_set(): return
        await asyncio.sleep(5)')
check "G1: stop flag → fine"                  '! has "$o" "G1"'
R3="$TMP/repo3"; mkdir -p "$R3"; printf 'services:\n  web:\n    command: uvicorn app.main:app\n  worker:\n    command: php artisan queue:work --tries=3\n  beat:\n    command: celery -A app worker\n    stop_grace_period: 90s\n' > "$R3/compose.yaml"
o=$(be_scan_repo "$R3")
check "G2: worker without grace period"       'has "$o" "warn compose.yaml:4 G2: worker service \"worker\""'
check "G2: web service and graced worker ok"  '! has "$o" ":2 G2" && ! has "$o" ":6 G2"'
printf 'services:\n  w:\n    command: rq worker default\n' > "$R3/compose.yaml"
check "G2: last service checked at end"       'has "$(be_scan_repo "$R3")" "compose.yaml:2 G2"'

echo "scan command"
P="$TMP/proj"; mkdir -p "$P/alembic/versions" "$P/app"
for i in $(seq -w 1 32); do printf 'def upgrade():\n    op.drop_column("t", "c%s")\n' "$i" > "$P/alembic/versions/0${i}_m.py"; done
printf 'import requests\nrequests.get(u)\n' > "$P/app/c.py"
out=$(bash "$SCAN" "$P")
check "newest 30 migrations by default"     'has "$out" "30 of 32 migrations" && ! has "$out" "001_m.py" && has "$out" "032_m.py"'
check "--all scans every migration"         'has "$(bash "$SCAN" "$P" --all)" "001_m.py"'
check "summary counts"                      'has "$out" "Result: 1 error(s), 30 warning(s), 0 info."'
check "by-rule table"                       'grep -qE "^ +30 M1$" <<<"$out" && grep -qE "^ +1 O1$" <<<"$out"'
check "--strict exits 1 on errors"          '! bash "$SCAN" "$P" --strict >/dev/null'
check "no --strict exits 0"                 'bash "$SCAN" "$P" >/dev/null'
rm "$P/app/c.py"
check "--strict passes without errors"      'bash "$SCAN" "$P" --strict >/dev/null'
check "missing dir: exit 2"                 'bash "$SCAN" "$TMP/none" >/dev/null; [ $? = 2 ]'
(cd "$P" && git init -q && git add alembic/versions/032_m.py && git -c user.name=t -c user.email=t@t commit -qm x)
check "git repo: tracked files only"        'has "$(bash "$SCAN" "$P")" "1 of 1 migrations"'

echo "hook"
hk() { jq -nc --arg p "$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$p, content:$c}}' | bash "$HOOK" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
H="$TMP/h"; mkdir -p "$H/alembic/versions" "$H/app/Jobs"
printf 'def upgrade():\n    op.alter_column("t", "a", new_column_name="b")\n' > "$H/alembic/versions/9.py"
out=$(hk "$H/alembic/versions/9.py" "x")
check "hook reads the file on disk"         'has "$out" "M2: rename breaks running code"'
check "hook message names the plugin"       'has "$out" "backend:" && has "$out" "expand → migrate → contract"'
out=$(hk "$H/new/alembic/versions/1.py" 'def upgrade():
    op.drop_column("t", "x")')
check "hook falls back to tool content"     'has "$out" "M1"'
printf '<?php\nclass J implements ShouldQueue { }\n' > "$H/app/Jobs/J.php"
out=$(hk "$H/app/Jobs/J.php" "x")
check "hook: job warnings, not info"        'has "$out" "J1" && ! has "$out" "J4"'
printf 'x = 1\n' > "$H/app/clean.py"
check "hook silent on clean file"           '[ -z "$(hk "$H/app/clean.py" x)" ]'
check "hook silent on other files"          '[ -z "$(hk "$H/web/a.tsx" "requests.get(u)")" ]'
check "hook off switch"                     '[ -z "$(printf "%s" "{\"tool_input\":{\"file_path\":\"$H/alembic/versions/9.py\"}}" | BACKEND_CHECK=off bash "$HOOK")" ]'
check "hook survives bad JSON"              'echo "not json" | bash "$HOOK"; [ $? = 0 ]'

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
