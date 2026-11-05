---
spec_version: 1
updated: 2026-11-05
---

# Shelf — Plan

## M0 — Foundations · status: done
goal: App runs locally and tests pass in CI.
demo: `npm test` green on main.

- [x] T1 · Express app skeleton + test runner · covers: setup · depends: - · size: S
- [x] T2 · Current book page · covers: R1 · depends: T1 · size: S

## M1 — Voting · status: active
goal: A club can add candidates, vote, and pick its next book.
demo: add 2 candidates, 3 members vote, close → winner is current book.

- [x] T3 · Add candidate books (API + list) · covers: R2 · depends: T1 · size: M
- [ ] T4 · Cast and change a vote · covers: R3 · depends: T3 · size: M
- [ ] T5 · Close vote and promote winner · covers: R4 · depends: T4 · size: M
- [!] T6 · Deploy to staging · covers: setup · depends: T1 · size: S — waiting for hosting account
- [ ] T7 · Tidy README · covers: - · depends: - · size: S

## Deferred
- R5 (should) — after M1, needs email provider decision

## Plan changes
| Date | Change | Why |
|---|---|---|

## Progress log
- 2026-11-04 · T1 [x] · goal .agent-log/goals/2026-11-04-t1-skeleton.md
- 2026-11-04 · T2 [x] · goal .agent-log/goals/2026-11-04-t2-current-book.md · R1 met
- 2026-11-05 · T3 [x] · goal .agent-log/goals/2026-11-05-t3-candidates.md
