---
name: adr
description: Write, number, and supersede Architecture Decision Records in docs/architecture/decisions/. Use when a decision is costly to reverse (repo shape, service split, database, auth approach, API style, hosting), when the user says "record this decision", "write an ADR", "why did we choose X", or when changing a decision already recorded in ARCHITECTURE.md.
---

# Architecture Decision Records

## Write a new ADR
1. List `docs/architecture/decisions/`. Next number = highest + 1, zero-padded to 4 (`0007`).
2. Filename: `NNNN-<kebab-case-title>.md`.
3. Fill [templates/adr.md](templates/adr.md). Context cites the driver from ARCHITECTURE.md §1.
4. Status `Accepted` if the user agreed in this session, otherwise `Proposed`.
5. Add a row to the Decisions table in ARCHITECTURE.md.

## Change a decision (supersede)
1. Write a new ADR with the new decision; its Context explains what changed.
2. In the old ADR change **only** the status line: `Superseded by NNNN`.
3. Update the affected ARCHITECTURE.md sections and the Decisions table.

## When an ADR is required
Repo shape · service shape · primary DB and each extra store · auth approach · API style · hosting/platform · any decision the user debated · any departure from house defaults.

## Hard rules
- Never rewrite the body of an accepted ADR.
- One decision per ADR.
- "Revisit when" is a measurable trigger, not "later".
