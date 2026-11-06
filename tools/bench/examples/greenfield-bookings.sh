#!/usr/bin/env bash
# Create the public greenfield benchmark: a repo whose base commit holds only a product brief, and whose
# "fix" commit holds a reference implementation + the hidden acceptance tests. Then write the case.
# Usage: greenfield-bookings.sh <repo-dir> [cases-dir]     (no dependencies beyond Node ≥ 20 and git)
set -euo pipefail
repo="${1:?repo dir}"; cases="${2:-$(cd "$(dirname "$0")/../../.." && pwd)/bench-cases}"
[ -e "$repo" ] && { echo "$repo exists"; exit 1; }
mkdir -p "$repo"; cd "$repo"; git init -q
g() { git -c user.name=bench -c user.email=bench@example.com "$@"; }
cat > BRIEF.md <<'B'
# Clinic bookings — brief

A small clinic wants online appointment booking to replace phone calls.

- Patients book a 30-minute slot between 09:00 and 17:00 (last slot starts 16:30), Monday–Friday.
- A slot can hold one booking. Double booking must be impossible, even with two requests at the same time.
- Patients cancel with their booking code; cancelling is allowed until 2 hours before the slot.
- Staff list a day's bookings.
- Must run in a container and deploy through CI. Start with an in-memory store behind an interface so a database can replace it later.

## Interface (fixed — other systems depend on it)
Node ≥ 20, no frameworks required. `src/app.js` exports `createApp({ now = () => new Date() } = {})` returning a Node `http.Server` (not listening).
- `POST /bookings` JSON `{ "name": string, "slot": "YYYY-MM-DDTHH:mm" }` → 201 `{ "code": string, "name", "slot" }`; 400 invalid input or slot outside hours/weekend/past; 409 slot taken.
- `GET /bookings?date=YYYY-MM-DD` → 200 `[{ "slot", "name" }]` sorted by slot (no codes).
- `DELETE /bookings/:code` → 204; 404 unknown code; 409 less than 2 hours before the slot.
Times are clinic-local and naive (no time zones). `npm test` runs the tests.
B
g add -A; g commit -qm "chore: project brief"
mkdir -p src test
cat > src/store.js <<'J'
export class MemoryStore {
  #bySlot = new Map(); #byCode = new Map();
  add(b) { if (this.#bySlot.has(b.slot)) return false; this.#bySlot.set(b.slot, b); this.#byCode.set(b.code, b); return true; }
  byCode(c) { return this.#byCode.get(c); }
  remove(c) { const b = this.#byCode.get(c); if (!b) return false; this.#byCode.delete(c); this.#bySlot.delete(b.slot); return true; }
  onDate(d) { return [...this.#bySlot.values()].filter((b) => b.slot.startsWith(d)).sort((a, b) => a.slot.localeCompare(b.slot)); }
}
J
cat > src/app.js <<'J'
import http from 'node:http';
import { randomBytes } from 'node:crypto';
import { MemoryStore } from './store.js';
const SLOT = /^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2})$/;
function parse(slot) {
  const m = SLOT.exec(slot ?? ''); if (!m) return null;
  const d = new Date(`${slot}:00`); if (Number.isNaN(d.getTime())) return null;
  const h = +m[2], min = +m[3], day = d.getDay();
  if (day === 0 || day === 6 || (min !== 0 && min !== 30) || h < 9 || h > 16) return null;
  return d;
}
export function createApp({ now = () => new Date(), store = new MemoryStore() } = {}) {
  const send = (res, code, body) => { res.writeHead(code, body === undefined ? {} : { 'content-type': 'application/json' }); res.end(body === undefined ? undefined : JSON.stringify(body)); };
  return http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://x');
    if (req.method === 'POST' && url.pathname === '/bookings') {
      let body = ''; for await (const c of req) body += c;
      let data; try { data = JSON.parse(body); } catch { return send(res, 400, { error: 'invalid JSON' }); }
      const at = parse(data?.slot);
      if (typeof data?.name !== 'string' || !data.name.trim() || !at || at <= now()) return send(res, 400, { error: 'invalid booking' });
      const b = { code: randomBytes(6).toString('hex'), name: data.name.trim(), slot: data.slot };
      return store.add(b) ? send(res, 201, b) : send(res, 409, { error: 'slot taken' });
    }
    if (req.method === 'GET' && url.pathname === '/bookings') {
      const d = url.searchParams.get('date'); if (!/^\d{4}-\d{2}-\d{2}$/.test(d ?? '')) return send(res, 400, { error: 'date required' });
      return send(res, 200, store.onDate(d).map(({ slot, name }) => ({ slot, name })));
    }
    const m = /^\/bookings\/([^/]+)$/.exec(url.pathname);
    if (req.method === 'DELETE' && m) {
      const b = store.byCode(m[1]); if (!b) return send(res, 404, { error: 'unknown code' });
      if (new Date(`${b.slot}:00`) - now() < 2 * 3600e3) return send(res, 409, { error: 'too late to cancel' });
      store.remove(m[1]); return send(res, 204);
    }
    send(res, 404, { error: 'not found' });
  });
}
J
cat > test/acceptance.test.js <<'J'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app.js';
const NOW = new Date('2026-11-09T08:00:00'); // Monday 08:00
async function api(t) {
  const app = createApp({ now: () => NOW }); await new Promise((r) => app.listen(0, r)); t.after(() => app.close());
  const base = `http://127.0.0.1:${app.address().port}`;
  return (method, path, body) => fetch(base + path, { method, headers: { 'content-type': 'application/json' }, body: body && JSON.stringify(body) })
    .then(async (r) => ({ status: r.status, body: r.status === 204 ? null : await r.json().catch(() => null) }));
}
test('book, list, cancel', async (t) => {
  const call = await api(t);
  const b = await call('POST', '/bookings', { name: 'Ada', slot: '2026-11-09T14:30' });
  assert.equal(b.status, 201); assert.ok(b.body.code);
  assert.deepEqual((await call('GET', '/bookings?date=2026-11-09')).body, [{ slot: '2026-11-09T14:30', name: 'Ada' }]);
  assert.equal((await call('DELETE', `/bookings/${b.body.code}`)).status, 204);
  assert.deepEqual((await call('GET', '/bookings?date=2026-11-09')).body, []);
});
test('no double booking, even concurrently', async (t) => {
  const call = await api(t);
  const r = await Promise.all(Array.from({ length: 10 }, (_, i) => call('POST', '/bookings', { name: `P${i}`, slot: '2026-11-10T10:00' })));
  assert.equal(r.filter((x) => x.status === 201).length, 1); assert.equal(r.filter((x) => x.status === 409).length, 9);
});
test('rejects bad slots', async (t) => {
  const call = await api(t);
  for (const slot of ['2026-11-09T08:30', '2026-11-09T17:00', '2026-11-09T10:15', '2026-11-14T10:00', '2026-11-06T10:00', 'tomorrow', '2026-11-09T07:00'])
    assert.equal((await call('POST', '/bookings', { name: 'X', slot })).status, 400, slot);
  assert.equal((await call('POST', '/bookings', { name: '', slot: '2026-11-09T10:00' })).status, 400);
  assert.equal((await call('POST', '/bookings', { slot: '2026-11-09T10:00' })).status, 400);
  assert.equal((await call('POST', '/bookings', { name: 'Late', slot: '2026-11-09T16:30' })).status, 201);
});
test('list is sorted and hides codes', async (t) => {
  const call = await api(t);
  await call('POST', '/bookings', { name: 'B', slot: '2026-11-11T15:00' }); await call('POST', '/bookings', { name: 'A', slot: '2026-11-11T09:00' });
  const l = (await call('GET', '/bookings?date=2026-11-11')).body;
  assert.deepEqual(l.map((x) => x.slot), ['2026-11-11T09:00', '2026-11-11T15:00']); assert.ok(l.every((x) => !('code' in x)));
});
test('cancel rules', async (t) => {
  const call = await api(t);
  const soon = await call('POST', '/bookings', { name: 'S', slot: '2026-11-09T09:30' });
  assert.equal((await call('DELETE', `/bookings/${soon.body.code}`)).status, 409);
  assert.equal((await call('DELETE', '/bookings/nope')).status, 404);
  const ok = await call('POST', '/bookings', { name: 'T', slot: '2026-11-09T10:00' });
  assert.equal((await call('DELETE', `/bookings/${ok.body.code}`)).status, 204);
});
J
printf '{ "name": "clinic-bookings", "type": "module", "private": true, "scripts": { "test": "node --test" } }\n' > package.json
g add -A; g commit -qm "feat: booking API with acceptance tests (reference)"
fix=$(git rev-parse HEAD); base=$(git rev-parse HEAD~1)
node --test >/dev/null 2>&1 && echo "reference passes its acceptance tests" || { echo "reference FAILS"; exit 1; }
git checkout -q "$base"
mkdir -p "$cases/greenfield-bookings"
jq -n --arg repo "$(pwd)" --arg base "$base" --arg fix "$fix" '{
  repo: $repo, base: $base, fix: $fix,
  task: "Build this project from the brief in BRIEF.md, foundation to deployment-ready: working code with tests, a Dockerfile, a CI workflow that runs the tests and builds the image, and a README explaining how to run and deploy it. Follow the interface in the brief exactly.",
  plugins: ["product","architecture","code-standards","testing","security","devops","collaboration","agent-ops"],
  setup: "", max_turns: 120, timeout: 3600,
  checks: [
    {type: "hidden_tests", paths: ["test/acceptance.test.js"], run: "node --test test/acceptance.test.js", weight: 6},
    {type: "cmd", run: "npm test", weight: 1},
    {type: "cmd", run: "ls Dockerfile", weight: 1},
    {type: "cmd", run: "ls .github/workflows/*.y*ml", weight: 1},
    {type: "grep", file: "README.md", pattern: "docker (build|run)", weight: 1},
    {type: "llm", rubric: "PASS only if: (1) double booking is impossible under concurrent requests by design (atomic check-and-insert in one place), (2) the store sits behind an interface a database could replace, (3) the agent wrote its own meaningful tests (not just the brief examples), (4) the Dockerfile runs as a non-root user with a pinned base image, (5) CI runs the tests and builds the image on pull requests. FAIL if two or more are missing.", weight: 3}
  ] }' > "$cases/greenfield-bookings/case.json"
echo "case written: $cases/greenfield-bookings/case.json"
