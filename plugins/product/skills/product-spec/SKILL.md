---
name: product-spec
description: Interview the user about the whole project and write docs/spec/SPEC.md — problem, users, key journeys, numbered requirements with acceptance checks, non-goals, success metrics, constraints. Also handles spec changes with a change log. Use when starting a project, when the user says "write the spec", "here's my idea", "PRD", "requirements", "what are we building", "add a feature to the spec", "change the requirements", or when SPEC.md is missing and work is about to start.
---

# Product spec

The spec is the project's long-lived "what". Goals come and go; the spec stays.

## Modes
| Situation | Mode |
|---|---|
| No SPEC.md | **Interview** → steps 1–4 |
| Code exists, no SPEC.md | **Recover**: draft from README, routes, UI, tests; then step 3 to confirm |
| SPEC.md exists, user adds/changes/drops something | **Change** → [references/change-control.md](references/change-control.md) |

## 1. Interview in rounds
Follow [references/interview.md](references/interview.md). Three short rounds (≤ 5 questions each). Each question carries your proposed answer so the user can reply "yes" or correct it. If the user gave a brief and says "don't ask", fill everything from the brief, mark each inferred item `(assumed)`, and list them as Open questions.

## 2. Write requirements properly
Follow [references/requirements.md](references/requirements.md). Every requirement:
- has an ID `R1`, `R2`… (never reused, never renumbered)
- has a priority: `must` / `should` / `could`
- is an observable behavior, not a design choice
- has an `accept:` line a person or test can check

## 3. Draft, show, confirm
Fill [templates/SPEC.md](templates/SPEC.md) into `docs/spec/SPEC.md`. Show the user: one-line vision, the `must` requirements, non-goals, open questions. Set `status: draft` until the user confirms, then `status: agreed` and `version: 1`.

## 4. Hand off
- No ARCHITECTURE.md → tell the user the next step is `system-design`.
- Architecture exists → next step is `project-plan`.
- Add to the project's CLAUDE.md: `Spec: docs/spec/SPEC.md — what we are building. Plan: docs/plan/PLAN.md — what's next.`

## Hard rules
- Non-goals are mandatory. A spec without them invites scope creep.
- Never write tech choices in the spec ("use Redis"). That belongs in ARCHITECTURE.md.
- Requirement IDs are permanent. Dropped requirements stay listed with `dropped` and a reason.
- `must` requirements ≤ ~12 for a first release. More → split into releases.
