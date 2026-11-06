---
name: prototype
description: Answer the riskiest question before committing to the full build — a throwaway prototype or spike with a written question, success and kill criteria and a timebox, ending in a keep / change / kill verdict that updates SPEC.md and an ADR. Covers logic/state models, UI variants, technical feasibility (APIs, performance, libraries), data sufficiency, and AI quality spikes. Use when the user says "prototype", "spike", "proof of concept", "POC", "try it first", "is this feasible", "mock it up", "which design", "before we commit", or when SPEC.md lists an unresolved risk (K1, K2…) or loop.sh says foundation/prototype.
---

# Prototype — buy the answer, not the code

A prototype is **throwaway work that answers one question** cheaply enough that being wrong costs hours, not weeks. It sits between the spec and the architecture: `SPEC risks (K…) → prototype → verdict → SPEC/ADR → architecture → plan`.

**Output:** `docs/prototypes/<slug>.md` (from [templates/PROTOTYPE.md](templates/PROTOTYPE.md)) with the verdict, plus the prototype on a `proto/<slug>` branch — never on main.

## Steps
1. **Pick the risk** — from SPEC `## Risks & unknowns` (`- [ ] K1 · question · prototype: slug`) or the user. One question per prototype.
2. **Write the card before any code** — question, *success* criterion (what result means "go"), *kill* criterion (what means "drop or change the plan"), timebox (default ½ day), what's faked. See [references/question-types.md](references/question-types.md).
3. **Pick the shape by question type** — [references/question-types.md](references/question-types.md):
   - logic/state model → shareable one-file HTML demo; UI → several radically different variants on the real page behind `?variant=`. Both follow Matt Pocock's `prototype` skill — use it when installed (`mattpocock-skills:prototype`, see UPSTREAM.md); the rules are summarised in the reference.
   - technical feasibility, data sufficiency, AI quality → a spike script with a measured result ([references/spikes.md](references/spikes.md)).
4. **Build it on `proto/<slug>`**, trivially runnable (one command or a double-clickable file), no persistence, no tests, no polish — and show the state/result after every action.
5. **Measure against the card** — numbers, screenshots or the user's reaction, not impressions. Stop at the timebox even if unfinished: "couldn't show it in ½ day" is a result.
6. **Verdict** — keep / change / kill, recorded in the card; then:
   - tick the risk in SPEC (`- [x] K1 … → keep, see docs/prototypes/slug.md`) and log any requirement change in the SPEC change log (`product-spec` change mode);
   - a decision that shapes the system → ADR (`architecture:adr`);
   - only the *validated logic module* or the winning variant's idea comes to main, rewritten to production standards in a planned task.
7. **Hand off** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/loop.sh" log prototype "<slug>: <verdict>"`, then follow `loop.sh next`.

## Hard rules
- No card, no prototype. Success and kill criteria are written *before* building.
- Prototype code never merges to main; the branch is the record.
- One question per prototype; a second question gets a second card.
- A "keep" verdict on a spike doesn't skip the real task's tests and review.
