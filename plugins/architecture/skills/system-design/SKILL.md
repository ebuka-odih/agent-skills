---
name: system-design
description: Entry point for designing or documenting a project's whole architecture. Use when starting a new project, when the user says "design the system", "how should I structure this project", "write the architecture doc", "plan the architecture", or when reviewing whether a change fits the architecture. Runs the drivers interview, walks every decision area, delegates deep areas to the repo-and-services, auth-design, data-design and api-design skills, and writes docs/architecture/ARCHITECTURE.md — the file every other skill in this marketplace reads.
---

# System design (orchestrator)

You coordinate. Deep decisions belong to sibling skills; this skill decides the order, collects the answers, and writes the record.

```
architecture/skills/
├── system-design/        ← you are here: modes, drivers, checklist, the record
├── repo-and-services/    monorepo vs polyrepo, monolith vs microservices, boundaries
├── auth-design/          authentication, authorization, multi-tenancy
├── data-design/          stores, ownership, migrations, PII, backups
├── api-design/           API style, contracts, versioning, errors
└── adr/                  writing and superseding decision records
```

**Outputs in the target project:**
- `docs/architecture/ARCHITECTURE.md` (from [templates/ARCHITECTURE.md](templates/ARCHITECTURE.md))
- `docs/architecture/decisions/NNNN-<slug>.md` (via the `adr` skill)

## 1. Pick the mode

Look for `docs/architecture/ARCHITECTURE.md` and for source code.

| Situation | Mode | Next |
|---|---|---|
| No code, no doc | **Design** | Steps 2 → 5 |
| Code, no doc | **Recover** | Steps 2 → 5, answering from the code first |
| Doc exists, user wants a change | **Amend** | `adr` skill, then update the doc's affected sections |
| Doc exists, reviewing a change or PR | **Check** | [references/check-mode.md](references/check-mode.md) |

## 2. Load the house defaults

Read [references/defaults.md](references/defaults.md). It overrides generic advice everywhere in this plugin. A decision taken from it without discussion is labelled **Default**.

## 3. Gather the drivers

Read `docs/spec/SPEC.md` first if it exists: users, journeys, requirements (R…/NFR…), constraints and non-goals are drivers already answered — don't ask them again, and cite requirement IDs in decisions ("Postgres RLS — NFR3 tenant isolation"). No spec and the user is starting a real project → suggest the `product-spec` skill first; continue without it only if they say so.

Then follow [references/drivers.md](references/drivers.md) for what's still unknown. One batch of at most 6 questions, each with a default answer. Don't decide anything until drivers are known.

## 4. Walk the decision areas, in order

[references/checklist.md](references/checklist.md) lists all 18 areas. For each area: one-line decision, the driver it follows from, status (**Decided / Default / Open / N/A — why**).

Hand off the deep areas — load the skill, follow it, bring its output back:

| Area | Skill |
|---|---|
| 2–3 Repo shape, service shape, boundaries | `repo-and-services` |
| 5–6 Authentication, authorization, tenancy | `auth-design` |
| 7 Data | `data-design` |
| 8 APIs and contracts | `api-design` |
| Every decision costly to reverse | `adr` |

Recommend one option per area. Name a runner-up only when the trade-off is close.

## 5. Write and present

1. Fill the template into `docs/architecture/ARCHITECTURE.md`. Every section filled or N/A. Context + container diagrams in Mermaid.
2. ADRs for: repo shape, service shape, primary DB, auth approach, API style, hosting, and anything the user argued about.
3. Every Open item goes in the Open questions table with owner, blocking date, recommended answer.
4. Add to the project's `CLAUDE.md` (create if missing):
   `Architecture: read docs/architecture/ARCHITECTURE.md before changing module or service boundaries.`
5. Tell the user: 5-line summary (repo, services, auth, DB, hosting) → Open questions with recommendations → file paths.

## Hard rules

- Every decision traces to a driver. No driver → it's a Default; label it.
- Auth is never left Open past this skill's run.
- The doc describes what **is**. Hopes go under "Planned evolution" with a measurable trigger.
- Never edit an accepted ADR. Supersede it.
