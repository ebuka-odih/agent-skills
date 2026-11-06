---
name: project-loop
description: Run a project end to end through every skill as one loop — foundation (spec, prototype, architecture, UI/AI/SEO/security/delivery design, plan) → build loop (one task at a time through goal, code, tests, review, PR, verify) → release → operate → evolve (new features and fixes back into the spec and plan). Also adopts an existing project: recovers SPEC and ARCHITECTURE from the code, records a baseline from every scanner, then grows it feature by feature. Use when the user says "take this from idea to production", "build the whole project", "end to end", "where are we", "what's next", "continue the project", "adopt this codebase", "add features to this project", "scale this app", or at the start of any session in a project with docs/project/LOOP.md.
---

# Project loop (conductor)

Skills talk to each other through **files**, not memory. Each phase reads the files the previous phase wrote, writes its own, and logs a hand-off line. `loop.sh` reads those files and says what comes next, so any session — or any agent — can pick the project up.

```
            ┌──────────── FOUNDATION ────────────┐
 idea ─▶ SPEC ─▶ prototype ─▶ ARCHITECTURE ─▶ UI · AI · SEO · SECURITY · DELIVERY ─▶ PLAN
                                                                                    │
     ┌──────────────────────────── BUILD LOOP (per task) ──────────────────────────┘
     ▼
  next-task ─▶ GOAL ─▶ code (domain skills) ─▶ tests ─▶ review ─▶ PR ─▶ verify-done ─▶ tick PLAN
     │  milestone done
     ▼
  RELEASE (delivery, release-and-rollback, site-audit) ─▶ OPERATE (observability, search-console, ai-learnings)
     │  new request / bug / metric
     ▼
  EVOLVE: SPEC change ─▶ (prototype if risky) ─▶ PLAN tasks ─▶ back into the build loop
existing code ─▶ ADOPT: recover SPEC + ARCHITECTURE, BASELINE from scanners ─▶ EVOLVE
```

## Every session
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/loop.sh" status` — mode (greenfield/existing), phase, contract files, **next skill and why**.
2. Run that skill. Its exit gate is in [references/phases.md](references/phases.md); don't move on until it passes.
3. Hand off: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/loop.sh" log <phase> "<what was produced> · next: <skill>"`.
4. Repeat. Stop and ask the user only at the decision points marked 🧑 in phases.md.

## Only what the project needs
Routing reads `## Profile` in SPEC.md (`ui / ai / seo: yes|no`, set with the user in product-spec). With no profile, `loop.sh` detects from the code (frontend deps, LLM SDKs or API hosts, sitemap/robots files) and the spec's words, and says so: `Domains: ui=on(profile) ai=off(profile) seo=on(detected)`. A profile "no" that the code contradicts is reported as a **mismatch**. Skills of off domains are never called; `loop.sh plugins > .claude/settings.json` (merge with existing settings) disables their plugins for this repo so even their descriptions stay out of context. Core plugins (product, agent-ops, architecture, code-standards, testing, security, collaboration, devops) stay on.

## Modes
| Situation | Read |
|---|---|
| New project | [references/phases.md](references/phases.md) — foundation → build → release → operate |
| Existing codebase (no SPEC/baseline) | [references/adopt.md](references/adopt.md) — recover the contract files, baseline, then evolve |
| New feature, bug, scaling work on a running project | [references/evolve.md](references/evolve.md) — every change enters through SPEC/PLAN |
| Who writes / reads which file | [references/contract.md](references/contract.md) |

## Hard rules
- The next step comes from `loop.sh` + PLAN.md, never from memory.
- A phase is done when its exit gate passes with evidence (verify-done), not when the skill finishes talking.
- Changes to *what* go through SPEC change control; changes to *how* through an ADR; nothing skips the build loop's tests and review.
- One task in progress per agent; parallel agents take different ready tasks and different files.
