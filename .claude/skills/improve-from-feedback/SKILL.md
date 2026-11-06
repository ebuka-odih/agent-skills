---
name: improve-from-feedback
description: Turn a report from an agent working on one of the user's projects (a gap, a wrong instruction, a missing tool, a regression the skills didn't prevent) into a general improvement of this skills library — logged, built with tests, versioned, pushed — and hand the result back to the project. Use in this repo when the user pastes or forwards feedback from another agent or project ("the X agent says…", "got this back from…", "the skill told it to…"), or when a benchmark or real run shows a skill failing.
---

# Improve the skills from project feedback

Project agents **use** the skills; this repo **changes** them. Feedback never becomes per-project tooling built by the project agent.

## Steps
1. **Log it** — add a row to `FEEDBACK.md` (anonymised: "project 1/2", no paths): date, what was reported, by whom (role, not name).
2. **Classify** — one of: *missing tool* (needs a script/template) · *wrong or missing guidance* (SKILL/reference text) · *skill didn't trigger* (description) · *tool bug* · *gap between skills* (loop/contract) · *not a skills issue* (project-specific → say so and stop).
3. **Generalise** — write the fix so every future project benefits: which plugin, which skill, which file. Prefer a reference/decision-table line or a tested script over prose.
4. **Prove it** — tests for scripts (+ mutation for decision logic), an eval case when it's about agent behaviour, and when the feedback came from a real fix, a bench case (`tools/bench/bench.sh new …`).
5. **Try it on the real project, read-only** — run the new tool against the project (live URL or a temp clone) and record what it finds.
6. **Ship** — version bump, CHANGELOG, run-all-tests, push, CI green; update installed plugins (`claude plugin marketplace update ebuka-skills` + `claude plugin update …`).
7. **Hand back** — write `.agent-log/handoffs/<project>-<topic>.md` (private): what to run, the findings, the exact commands; close the FEEDBACK.md row with the version.

## Hard rules
- Don't edit the project's repo from here unless the user asks; hand back instead.
- Public files stay anonymised; project names and paths only in gitignored files.
- A feedback item is closed only when the change is pushed and the project has its handoff.
