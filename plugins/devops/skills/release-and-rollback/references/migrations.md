# Backward-compatible migrations

| Change | Release N (expand) | Release N+1 (migrate) | Release N+2 (contract) |
|---|---|---|---|
| Rename column `a` → `b` | add `b`, write both | backfill `b`, read `b` | drop `a` |
| Add NOT NULL column | add nullable + default in code | backfill | add NOT NULL constraint |
| Drop column | stop reading it in code | stop writing it | drop column |
| Split table | create new table, dual-write | backfill, read new | drop old columns |

## Rules
- Large tables: create indexes concurrently (`CREATE INDEX CONCURRENTLY`); batch backfills in a queued job, not in the migration.
- Migrations run before the new code serves traffic, and must work with the old code still running.
- Every migration has a tested `down` **or** a written note why it's forward-only.
- Before running against production: backup / snapshot confirmed, and the user approved.

## A migration failed in production
1. Stop: don't re-run blindly, don't `migrate:fresh` / `migrate:reset` / `db:wipe` (destroys data).
2. Check state: `php artisan migrate:status` / `alembic current` — which steps applied?
3. App still healthy on old schema? → leave it, roll back the code if needed.
4. Write a **forward fix** migration that completes or reverses the partial change, test it on a staging copy, then apply with approval.
5. Restore from backup only if data was lost — and only with the user's explicit decision.
