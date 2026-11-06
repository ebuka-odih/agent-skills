# Change → safe pattern

| Change | Risk | Safe pattern |
|---|---|---|
| Add nullable column | none | single deploy |
| Add column with constant default | Postgres ≥ 11 / MySQL 8 instant: safe; volatile default (e.g. `now()`, random) rewrites the table | constant default, or nullable + backfill |
| Add NOT NULL column | fails on existing rows / long lock | add nullable → backfill in batches → (PG) `ADD CONSTRAINT … CHECK (col IS NOT NULL) NOT VALID` → `VALIDATE CONSTRAINT` → `SET NOT NULL` |
| Rename column/table | breaks running code instantly | add new → dual-write → backfill → read new → stop writing old → drop old (≥ 3 deploys) |
| Drop column/table | running code still selects it | stop using it in code (deploy) → drop in the next deploy; Laravel/Eloquent `$hidden` doesn't count — remove from queries |
| Change column type | table rewrite + lock; data loss on narrowing | new column of the new type → dual-write/backfill → switch → drop old |
| Add index (large table) | locks writes for the build | PG: `CREATE INDEX CONCURRENTLY` (outside a transaction); MySQL: `ALGORITHM=INPLACE, LOCK=NONE` |
| Add unique constraint | lock + fails on duplicates | dedupe first; PG: unique index concurrently → `ADD CONSTRAINT … USING INDEX` |
| Add foreign key | validates all rows under lock | PG: `ADD CONSTRAINT … NOT VALID` → `VALIDATE CONSTRAINT` separately |
| Backfill | long transaction, replication lag, lock pile-up | batches of 1–10k by primary key, commit per batch, sleep between, resumable; run as a job/command |
| Enum / check change | rewrites or locks | add values only; removals follow the column-drop pattern |

## Always
- `SET lock_timeout = '5s'` (and `statement_timeout`) at the top of risky DDL; retry the deploy step on timeout.
- One concern per migration file; down migrations that work, or a written reason.
- Ship the code that tolerates both schemas *before* the contract step.
