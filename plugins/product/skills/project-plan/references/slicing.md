# Slicing milestones and tasks

## Milestones: vertical, not horizontal
| Horizontal (avoid) | Vertical (do) |
|---|---|
| M1 database, M2 API, M3 UI | M1 a member books one class and pays (DB + API + UI, minimal) |
| Nothing usable until the end | Every milestone is demoable to a real user |

Each milestone has:
- **Goal:** one sentence a user would care about
- **Demo:** the check that proves it (`demo: member books + pays on staging`)
- **Covers:** the journey(s) and requirement IDs

## Order
1. **M0 Foundations** (only if no code yet): repo, CI, deploy to staging, auth skeleton — from ARCHITECTURE.md. Keep it ≤ 5 tasks.
2. **M1** the riskiest or most valuable journey, thinnest version.
3. Next milestones by priority: remaining `must`s, then `should`s.
4. Put risky unknowns (third-party API, performance) early, as a spike task: `T3 · Spike: Stripe Connect payouts · covers: R12 · size: S`.

## Tasks
- Done = observable. "Add model" isn't a task; "Member can see their bookings list (API + page)" is.
- Each task ends with something that runs or passes a test.
- Include the test work inside the task, not as a separate "write tests" task.
- 5–12 tasks per milestone. More → split the milestone.
