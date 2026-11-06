# Race → guard

| Race | Example | Guard | Laravel | SQLAlchemy / Postgres |
|---|---|---|---|---|
| Double submit / client retry | user double-clicks "Pay"; mobile retries on timeout | **Idempotency key**: store `(key, request hash) → response`, unique on key, TTL ~24 h; replay returns the stored response; same key + different body → 422 | middleware storing in a table/cache with `Cache::lock("idem:$key")` | table `idempotency_keys(key PK, request_hash, status, response, created_at)`; `INSERT … ON CONFLICT DO NOTHING RETURNING` decides who runs |
| Check-then-insert | "is the slot free?" then insert → two bookings | **Unique constraint** (+ partial unique index for "active" rows); catch the violation → 409 | `$table->unique([...])`; catch `UniqueConstraintViolationException` | `UniqueConstraint`/partial index; `insert(...).on_conflict_do_nothing()` or catch `IntegrityError` |
| Lost update | two admins edit the same record; last write wins silently | **Optimistic locking**: `version` column; `UPDATE … WHERE id = :id AND version = :v` → 0 rows = 409 Conflict | `where('version', $v)->update([... 'version' => $v + 1])` | `__mapper_args__ = {"version_id_col": version}` → `StaleDataError` → 409 |
| Counter / balance | two orders decrement the same stock | **Atomic update** with a guard in the WHERE | `->where('stock', '>=', $n)->decrement('stock', $n)` (check affected rows) | `update(T).where(T.id == i, T.stock >= n).values(stock=T.stock - n)` → rowcount |
| Multi-row invariant | transfer between accounts | `SELECT … FOR UPDATE` on the rows, in a consistent order (by id) to avoid deadlocks | `lockForUpdate()` inside `DB::transaction` | `.with_for_update()` inside `session.begin()` |
| Singleton work | two schedulers run the same sweep | **Lock**: Postgres advisory lock / Redis lock with TTL | `Cache::lock('sweep', 300)->get(fn …)`; `->withoutOverlapping()->onOneServer()` | `SELECT pg_try_advisory_xact_lock(:k)` |
| Duplicate message delivery | queue redelivers after a crash | idempotent consumer: processed-ids table / state check before the side effect | `ShouldBeUnique`, state check | unique `processed_messages(id)` insert first |

## Testing
```python
results = await asyncio.gather(*(client.post("/bookings", json=b, headers={"Idempotency-Key": "k1"}) for _ in range(10)))
assert sum(r.status_code == 201 for r in results) == 1   # replays return the same 201 body or 409, never a second booking
```
- Run against Postgres (testcontainers or the CI service), with separate sessions per request.
- Assert on the database afterwards (exactly one row / one charge), not only on responses.
