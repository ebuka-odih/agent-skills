# Production incident runbook

1. **Stop the bleeding** (minutes): roll back to the previous artifact, or turn the feature flag off. Don't debug in production while users are failing.
2. **Communicate**: post in the incident channel what's broken, impact, and next update time. Status page for user-visible outages.
3. **Diagnose** with observability: what changed (deploy, config, traffic, dependency), error logs by request ID, traces for slow paths.
4. **Fix forward** on a branch with a regression test; normal PR + checks; deploy with approval.
5. **Write up** within 2 working days (blameless): timeline, impact, root cause, what detected it, action items as PLAN tasks with owners. Add a LEARNINGS/ADR entry if a rule changes.

## Never during an incident
- Destructive data commands (`migrate:fresh`, `DROP`, `TRUNCATE`, `db:wipe`, `docker volume rm` on data volumes).
- Force-pushing `main` or deleting tags/releases.
- Disabling alerts or checks to get a deploy through.
