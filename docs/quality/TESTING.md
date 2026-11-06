# How the skills are tested

The repo applies its own `testing` plugin to itself. `test-strategy` picks techniques from the conditions of the code; this page records what was run and what it found.

## 1. The plan — `test-plan.sh` on this repo
Running the planner on every script added since the first commit recommended:

| Condition | Files | Technique |
|---|---|---|
| Critical rule (guards, gates, redaction) | `git-guard.sh`, `secret-guard.sh`, `infra-guard.sh`, `done-gate.sh`, `lib.sh` | **mutation testing** |
| Pure logic over many inputs (scanners, parsers, pattern tables) | `leftover-scan.sh`, `patterns.sh`, `parse.sh`, `devops-scan.sh`, … | **property / fuzz testing** |
| Everything | all scripts | base layer: script tests per plugin |

Dogfooding found two planner gaps, fixed before running the rest: guard/gate/hook scripts weren't recognised as critical, and eval fixture files (deliberately buggy code used by evals) were treated as real code.

## 2. Base layer — script tests
`tools/run-all-tests.sh` runs every plugin's `tests/run.sh`:

| Plugin | Checks |
|---|---|
| agent-ops | 38 |
| ai-engineering | 10 |
| code-standards | 37 |
| collaboration | 33 |
| devops | 53 |
| product | 29 |
| security | 34 |
| testing | 24 |
| frontend | 51 |
| seo | 150 |
| bench harness | 53 |
| **Total** | **512** |

## 3. Mutation testing — do the tests catch broken guards?
No mutation tool supports bash, so `tools/mutate-bash.sh` applies one mutation at a time (neutralise a deny/ask decision, flip a comparison, delete a rule or pattern, negate a condition, disable a redaction rule), runs that plugin's tests, and counts killed vs surviving mutants.

| Script | First run | After fixes |
|---|---|---|
| `devops/infra-guard.sh` | 34/34 (100%) | 34/34 (100%) |
| `collaboration/git-guard.sh` | 16/18 (88%)* | 18/18 (100%) |
| `security/secret-guard.sh` | 2/3 (66%) | 3/3 (100%) |
| `security/patterns.sh` | 4/9 (44%) | 9/9 (100%) |
| `agent-ops/lib.sh` (redaction) | 0/0 → 1/6 (16%) | 6/6 (100%) |
| `agent-ops/done-gate.sh` | 5/6 (83%) | 5/6 — 1 equivalent mutant, accepted |
| `frontend/ui-patterns.sh` | 9/9 (100%) | 9/9 (100%) |
| `code-standards/leftover-scan.sh` | 1/1 | 5/5 (100%, new awk-rule operator) |
| `seo/seo-scan.sh` | 41/41 (100%) | 44/44 (100%, new `issue`/`finding` operators) |
| `seo/seo-crawl.sh` | 13/30 (43%) | 28/30 (93%) — 2 equivalent mutants |
| `seo/page-speed.sh` | 7/8 (87%) | 8/8 (100%) |
| `seo/gsc-report.sh` | 2/2 (100%) | 2/2 (100%) |
| `tools/bench/bench.sh` | 5/6 (83%) | 6/6 (100%) |

\* Both git-guard survivors were a bug in the mutation runner itself (awk `-v` stripped backslashes, changing `\s` to `s`), not test gaps. Fixed by passing the mutant through `ENVIRON`, plus a check that exactly one line differs.

**Real gaps found and closed:**
- 5 of 9 secret patterns (GitHub PAT, Anthropic, OpenAI, Slack, Google) could be deleted without any test failing → added one test per key type asserting the guard names it.
- The `.env.example` rule could be removed (the generic rule still denied) → test now asserts the specific reason.
- 5 of 6 log-redaction rules were untested (overlapping rules hid each other) → one isolated test per rule.

**Accepted survivor:** `done-gate.sh` line 40 (`-gt 0` → `-ge 0`). With zero open criteria the gate's fail-open safety net exits before the mutated line matters, so behaviour is identical (equivalent mutant).

## 4. Property / fuzz testing — hooks never crash
`tools/fuzz-hooks.sh` sends seeded random inputs to all 10 hook scripts: valid hook JSON with hostile values (shell metacharacters, SQL, unicode, emoji, format strings, path traversal, key-shaped strings, 7 KB payloads), wrong JSON shapes, and invalid JSON. Properties checked on every run:

1. exit code 0 (a hook must never break the session)
2. output is empty or valid JSON
3. any decision is one of allow / deny / ask / block
4. finishes in under 3 seconds

Result: **2,890 runs (seeds 7, 42, 11), 0 violations.** One run flagged `secret-guard.sh` at 4 s; it measured 0.1 s in isolation and didn't reproduce on replay — machine load, not the guard.

## 5. Skill behaviour — evals
Each plugin has `evals/` cases run with `claude plugin eval`, comparing an agent with the plugin against one without. Results are in the README table. Evals call the model and count against usage limits, so they run locally rather than in CI.

## 6. Project benchmark — real tasks from finished projects
`tools/bench/bench.sh` replays a shipped fix from its parent commit, with and without the plugins. It scores each run with the fix's own tests (copied in after the agent finishes), plus optional cmd/grep checks and an LLM judge that sees the shipped diff. Cases are private (`bench-cases/`, gitignored). Before a case is used, its hidden tests are checked to **fail at base and pass at the fix**. The first five cases (four from one project, one from another) all met that bar. The harness itself is tested with a fake agent and judge: 53 checks, mutation 6/6.

## 6. CI
`.github/workflows/ci.yml`: script tests + fuzzing + repo security self-scan on every push and PR; mutation testing weekly and on demand.

## Run it yourself
```bash
bash tools/run-all-tests.sh               # validate + script tests + fuzz
bash tools/run-all-tests.sh --mutation    # + mutation testing (~10 min)
cd plugins/<domain> && claude plugin eval . --allow-tools Write Edit Bash --scaffold --no-publish   # skill evals
```
