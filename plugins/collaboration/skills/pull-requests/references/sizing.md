# PR size and splitting

| Changed lines (excl. lockfiles, generated, snapshots) | Review quality |
|---|---|
| < 200 | thorough |
| 200–400 | good |
| > 400 | skimmed — split unless it's mechanical (rename, codemod, generated) |

## How to split
1. **Prep first** — refactors and renames with no behavior change, merged on their own.
2. **Then the feature** — behind a flag if it can't ship half-done.
3. **Stacked PRs** — PR2 based on PR1's branch; say so in PR2's body ("Based on #12"). Rebase PR2 after PR1 merges.
4. **By layer only when each layer is useful alone** (e.g. API + tests, then UI). Otherwise split by user-visible slice.

## When a big PR is fine
Generated migrations, dependency bumps with lockfiles, mass renames by tool. Say "mechanical — reviewed the generator, not each line" in the body.
