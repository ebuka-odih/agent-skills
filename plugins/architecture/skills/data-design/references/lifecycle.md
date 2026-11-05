# Change and lifecycle

## Zero-downtime migrations (expand → migrate → contract)
1. **Expand:** add new column/table, nullable or with default. Deploy code that writes both.
2. **Migrate:** backfill in batches (no long locks). Switch reads to the new shape.
3. **Contract:** remove the old column in a later release, after no code reads it.

Never in one deploy: rename a column, drop a column still read, add a NOT NULL column without default to a large table. Create indexes concurrently on large tables.

## Backups
- Automated daily full + point-in-time recovery meeting the RPO from the drivers.
- Stored in a different account/region from production.
- Restore drill at least quarterly; record the date and time-to-restore in the doc.

## Retention and deletion
| Data class | Example | Default retention |
|---|---|---|
| Account data | profile, settings | Life of account + 30 days |
| Transactional | invoices, orders | Legal requirement (often 7–10 years) |
| Logs | app/access logs | 30–90 days |
| Audit log | security events | 1 year+ |

User erasure (GDPR): one documented job deletes or anonymizes across DB, object storage, search, caches, analytics, and backups (by expiry).

## PII
- Keep an inventory: table.column → data class → why collected.
- Encrypt sensitive columns at the application layer (tokens, government IDs, health data).
- PII never in logs, URLs, or analytics events.
