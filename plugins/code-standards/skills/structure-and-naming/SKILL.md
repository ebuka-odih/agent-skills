---
name: structure-and-naming
description: Decide where new code goes and what to call it — module placement from ARCHITECTURE.md, feature folders, file and class naming per stack, function/variable naming, size limits and when to split a file or function. Use when creating files, classes, components or modules, when the user asks "where should this go", "what should I name this", "this file is too big", "how should I organise this", or when writing-code reaches step 5.
---

# Structure and naming

## Where it goes
1. ARCHITECTURE.md says which module owns the behaviour → put it there. No doc → follow the nearest existing feature.
2. Inside a module, by **role**: entry (controller/router/page) → use case (action/service/hook) → domain (models, value objects, pure logic) → infrastructure (DB, HTTP clients, queues).
3. New folder only when ≥ 3 files share a reason to exist. Otherwise extend the existing one.
4. Stack layouts: see `../writing-code/references/{laravel,fastapi,typescript-react}.md`.

## Naming
Follow [references/naming.md](references/naming.md). The short version:
- Names say **what it is / what it does in the domain**, using words from SPEC.md and ARCHITECTURE.md — not `data`, `info`, `manager`, `helper`, `utils`, `handle2`.
- Functions: verb + object (`cancelBooking`, `calculate_refund`). Booleans: `is/has/can/should`.
- Same concept, same word everywhere (don't mix `member`, `user`, `customer` for one thing).

## Size and splitting
| Signal | Do |
|---|---|
| Function > ~40 lines or > 3 nesting levels | Extract steps into named functions; early returns |
| File > ~400 lines or two unrelated reasons to change | Split by responsibility |
| Class with many `if type ==` branches | Polymorphism, strategy map, or enum method |
| Same 3+ lines in 3 places | Extract — but only on the third copy |
| Parameter list > 4 | Typed object / DTO |

## Hard rules
- No new "misc" files (`utils.py`, `helpers.php`, `common.ts`) — name the concept instead.
- Don't rename or move unrelated code in a feature change; do it in a separate refactor PR.
