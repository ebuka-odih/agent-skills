# Changing an agreed spec

Specs change. Silent changes are what break long projects.

## Steps
1. Restate the change in one line and classify it:
   - **add** — new requirement → next free ID
   - **change** — edit an existing requirement → keep the ID, mark `status: changed`
   - **drop** — keep the line, set `status: dropped — <reason>`
2. Show the impact before editing:
   - Which tasks in `docs/plan/PLAN.md` cover the affected IDs (`grep -n "R7" docs/plan/PLAN.md`)
   - Done tasks that may need rework
   - Whether a milestone date or scope moves
3. Get the user's OK for any change to a `must`.
4. Edit SPEC.md, bump `version`, add a Change log row: date · version · IDs · what · why.
5. Run `project-plan` in **Re-sync** mode so the plan matches.

## Scope creep check
If a request adds a `must` to an active milestone, ask: "Add to this milestone (moves the date) or the next one?" Default: the next one.
