#!/usr/bin/env bash
set -euo pipefail
G="git -c user.name=dev -c user.email=dev@example.invalid"
git init -q -b main
mkdir -p docs/spec docs/plan app tests
cat > docs/spec/SPEC.md <<'SPEC_EOF'
---
status: agreed
version: 1
updated: 2026-11-05
---

# Shelf — Spec

## Vision
Book clubs track what they read and vote on the next book.

## Users
| Role | Goal | How often |
|---|---|---|
| Member | see the current book, vote | weekly |
| Organiser | add books, close votes | weekly |

## Key journeys
- **J1** Member: open club → see current book → vote on next book
- **J2** Organiser: add candidate books → close the vote → winner becomes current book

## Requirements
- **R1** (must) A member can see the club's current book with title and author.
  accept: GET /clubs/1 shows the current book's title and author.
  journey: J1 · status: met
- **R2** (must) An organiser can add a candidate book by title and author.
  accept: POST /clubs/1/candidates with title+author → appears in the candidate list.
  journey: J2 · status: open
- **R3** (must) A member can cast one vote per round; voting again changes their vote.
  accept: second vote by the same member replaces the first; tally counts one vote per member.
  journey: J1 · status: open
- **R4** (must) An organiser can close the vote; the top candidate becomes the current book.
  accept: close → current book = highest tally; ties go to the earliest-added candidate.
  journey: J2 · status: open
- **R5** (should) Members get an email when a new current book is chosen.
  accept: closing a vote sends one email per member.
  journey: J2 · status: open
- **R6** (could) Members can rate finished books 1–5.
  accept: rating stored and averaged per book.
  status: dropped — out of scope for v1, user decision 2026-11-05

## Non-goals (this release)
- Reading progress tracking
- Discussion threads

## Change log
| Date | Version | IDs | Change | Why |
|---|---|---|---|---|
| 2026-11-05 | 1 | R6 | dropped | keep v1 small |
SPEC_EOF
cat > docs/plan/PLAN.md <<'PLAN_EOF'
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
PLAN_EOF
printf 'def current_book(club):\n    return club.book\n' > app/books.py
printf 'node_modules/\n.env\n' > .gitignore
$G add -A && $G commit -qm "chore: initial project"
$G switch -q -c feat/T4-cast-vote
printf 'VOTES = {}\n\n\ndef cast_vote(member_id, candidate_id):\n    """One vote per member per round; a new vote replaces the old one."""\n    VOTES[member_id] = candidate_id\n\n\ndef tally():\n    counts = {}\n    for c in VOTES.values():\n        counts[c] = counts.get(c, 0) + 1\n    return counts\n' > app/votes.py
printf 'from app.votes import cast_vote, tally, VOTES\n\n\ndef test_revote_replaces():\n    VOTES.clear(); cast_vote(1, "a"); cast_vote(1, "b")\n    assert tally() == {"b": 1}\n' > tests/test_votes.py
printf 'scratch notes, not part of the change\n' > notes-local.txt
