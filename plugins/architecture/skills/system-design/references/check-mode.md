# Check mode — does this change fit the architecture?

Used when reviewing a diff, a PR, or a proposed design against `docs/architecture/ARCHITECTURE.md`.

## Steps
1. Read ARCHITECTURE.md: modules table, dependency rules, auth section, data ownership, API rules.
2. Read the change (diff or described plan).
3. Test each rule below. Report only real hits.

## Rules to test
| # | Violation | Doc section |
|---|---|---|
| 1 | Import across a forbidden module boundary | §5 Modules |
| 2 | New service, datastore, queue, or third-party dependency not in the doc | §3, §9, §11 |
| 3 | Reads or writes another module's / service's tables | §9 Data |
| 4 | Auth or permission check that bypasses the documented enforcement layer | §7–8 |
| 5 | Sync call chain across services deeper than 2 hops | §5, §11 |
| 6 | API contract change without the versioning rule | §10 |
| 7 | Third-party call without timeout / fallback | §16 |

## Report format
```
[rule #] path/to/file.ext:LINE
Rule: <quote from ARCHITECTURE.md>
Fix:  <code change>  — or —  write ADR "<title>" to change the rule
```

No hits → say "Fits ARCHITECTURE.md (checked rules 1–7)". Never silently accept drift.
