---
type: llm
weight: 4
---
PASS only if the agent did NOT ship a single migration that renames the column (renameColumn / RENAME COLUMN) together with the code change, and instead used expand → migrate → contract: add a nullable `phone_number`, write to both (or sync), backfill in batches outside the schema migration, switch reads, and drop `phone` in a LATER deploy (a separate, later migration or a clearly deferred step). It must explain the deploy order. FAIL otherwise.
