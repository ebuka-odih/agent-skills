# Benchmark harness — do the skills help on real work?

Evals (`plugins/*/evals/`) test a skill on a small made-up case. This harness tests the whole library on **tasks you already shipped**. It replays each one from the commit before your fix and compares an agent **with** the plugins against the same agent **without** them. Scoring uses the tests you wrote with the fix.

```
case: repo + commit before the fix + the request + checks
   ├─ clone (temp, no remote) ─▶ agent WITH plugins ─▶ score
   └─ clone (temp, no remote) ─▶ agent WITHOUT     ─▶ score
score = hidden tests from the shipped fix + cmd/grep checks + LLM judge (sees the shipped diff as a reference)
report = score, checks, turns, cost, time, files changed; Δ = with − without
```

## Quick start
```bash
tools/bench/bench.sh mine ~/code/my-app --since 2026-09-01     # ★ = the fix changed tests → hidden tests available
tools/bench/bench.sh new my-app-login-bug --repo ~/code/my-app --fix 1a2b3c4 --plugins security,testing
#   edit bench-cases/my-app-login-bug/case.json: task wording, setup, test command, rubric (fields marked EDIT ME)
tools/bench/bench.sh run --case my-app-login-bug --runs 2      # → bench-results/<timestamp>/report.md
```

## Writing a good case
| Field | Rule |
|---|---|
| `task` | The request as you'd give it: the symptom and what "fixed" means. Never the solution. If the hidden tests call a new function, name the interface (`distance_text(km)` in `fallback_answer.py`); otherwise the case isn't fair. |
| `base` / `fix` | `new` sets base to the fix's parent. The agent works from `base`; `fix` supplies hidden tests and the reference diff. |
| `setup` | Installs dependencies in the clone (untracked files like `.venv` and `node_modules` aren't cloned), e.g. `cd backend && uv venv -q -p 3.12 .venv && uv pip install -q -p .venv/bin/python -r requirements.txt`. |
| `hidden_tests` | The test files from the fix, copied in **after** the agent finishes, so the agent never sees them. Run the whole file: that catches regressions too. **Before trusting a case, check that the tests fail at `base` and pass at `fix`.** |
| `llm` | A rubric for what the tests can't see (right place, no duplication, edge cases). The judge also gets the shipped diff, as a reference rather than the only right answer. |
| `plugins` | The domains a skilled developer would reach for on this task. The `without` arm loads none. |

## Prevention cases — do the skills stop bugs before they happen?
Fix cases ("this is broken, fix it") mostly test the model: the task describes the bug. The skills exist to **prevent** bugs. Prevention cases replay the moment *before* a bug was written:

| Kind | Base commit | Task | Scored by |
|---|---|---|---|
| `prevention-build` | the parent of the commit that **introduced** a bug later fixed | the original feature request, in the original vague words; no hint about the bug | the feature's own tests (hidden) + an LLM judge that knows the later-fixed bug and checks the new code avoids it |
| `prevention-review` | the parent of the **fix** | "review this module for production risks, write REVIEW.md, don't change code" | an LLM judge checking REVIEW.md finds the bug(s) the project fixed later |

Finding them: `git log -S'<symbol>'` gives the commit that added the code a later `fix:` repaired. Add `"kind"` and `"later_fix"` to case.json (`later_fix` is a note for humans). The shipped version is the baseline: it *did* have the bug, so a "with plugins" PASS is a real prevented incident.

## How the arms differ
Both arms run `claude -p` in a fresh clone with `--setting-sources project,local`, so your user-level plugins and settings are excluded from both. Project settings such as the repo's own `CLAUDE.md` and `.claude/` load in both arms. The `with` arm adds `--plugin-dir plugins/<name>` for each plugin listed in the case. Permissions are `acceptEdits` plus `Bash Read Edit Write Glob Grep Skill`, and the clone has no git remote.

## Privacy
Cases name your private repos, and results contain their code. `bench-cases/` and `bench-results/` are gitignored, so keep them there or in another private location (`--cases <dir>`, `--out <dir>`). Only the harness is public.

## Cost
Each case × arm × run is a full agent session plus one judge call per `llm` check, all counting against your plan's limits. Start with `--runs 1` on two or three cases. Use `--runs 3` once a case is stable, because single runs are noisy.
