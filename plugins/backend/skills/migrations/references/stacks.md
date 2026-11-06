# Stack snippets

## Laravel (Postgres)
```php
return new class extends Migration {
    public $withinTransaction = false;              // required for CONCURRENTLY
    public function up(): void {
        DB::statement("SET lock_timeout = '5s'");
        DB::statement('CREATE INDEX CONCURRENTLY IF NOT EXISTS bookings_slot_idx ON bookings (slot)');
    }
    public function down(): void { DB::statement('DROP INDEX CONCURRENTLY IF EXISTS bookings_slot_idx'); }
};
```
- Expand: `$table->string('phone_e164')->nullable();` — no `->change()` on hot tables in the same deploy.
- Backfill: an Artisan command or queued job: `Model::whereNull('x')->chunkById(1000, fn ($rows) => …)`.

## Alembic (async SQLAlchemy app, Postgres)
```python
def upgrade() -> None:
    op.execute("SET lock_timeout = '5s'")
    op.add_column("bookings", sa.Column("phone_e164", sa.String(), nullable=True))
    with op.get_context().autocommit_block():
        op.create_index("bookings_slot_idx", "bookings", ["slot"], postgresql_concurrently=True, if_not_exists=True)

def downgrade() -> None:
    with op.get_context().autocommit_block():
        op.drop_index("bookings_slot_idx", table_name="bookings", postgresql_concurrently=True, if_exists=True)
    op.drop_column("bookings", "phone_e164")
```
- NOT NULL safely: `op.execute("ALTER TABLE t ADD CONSTRAINT t_x_nn CHECK (x IS NOT NULL) NOT VALID")` → next migration `VALIDATE CONSTRAINT` → `op.alter_column("t", "x", nullable=False)`.
- `create_all()` in bootstrap scripts must produce the same constraints/indexes as migrations (partial unique indexes included) — or tests pass on a schema production doesn't have.
