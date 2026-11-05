---
type: llm
weight: 4
focus: { source: file, path: RELEASE.md }
---
The change renames bookings.seats → spots in one migration and the new code reads `spots` only.

PASS only if the plan:
1. flags that the rename is not backward compatible (old code still running during deploy / after rollback would break) and recommends expand → migrate → contract (add `spots`, dual-write/backfill, switch reads, drop `seats` later) — or explicitly blocks the release until that's done;
2. has concrete rollback steps (redeploy previous artifact) that still work with the schema state;
3. requires a backup/snapshot before migrating;
4. lists post-deploy verification (error rate, latency, specific checks for bookings) and a rollback trigger.
FAIL if it treats the rename as safe to ship as-is.
