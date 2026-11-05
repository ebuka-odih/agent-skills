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
  journey: J1 · status: open
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
