# Question types → prototype shape

| Question | Shape | Done when | Typical timebox |
|---|---|---|---|
| Does this state model / business rule hold up? | **Logic demo**: one self-contained HTML file, pure logic module (reducer / state machine / pure functions) + free-play buttons + guided scenario tabs, domain language | a non-developer drives the awkward scenarios and nothing "shouldn't be possible" happens | 2–4 h |
| What should this screen look like? | **UI variants**: 3 (max 5) *structurally* different variants on the real route behind `?variant=`, floating switcher (←/→), hidden in production | the user picks one or names the mix ("header from B, list from C") | ½ day |
| Will this flow make sense end to end? | **Clickable flow**: 3–6 screens with fake data, real navigation, no backend | 3 people complete the task without help; note where they hesitate | ½–1 day |
| Can the tech do it? (API, library, performance, platform limit) | **Tech spike**: smallest script that hits the real API/library with production-like input and prints the measured number | the number beats or misses the success criterion | 2–4 h |
| Do we have enough data? | **Data spike**: query/sample the real source, count against the threshold the product needs (e.g. ≥ 5 items per area × category) | coverage table vs threshold | 2–4 h |
| Is the model good enough? | **AI spike**: 20–50 real examples, one prompt, the cheapest model that might work, scored by a simple rubric | accuracy/latency/cost vs the card's targets; failures categorised | ½ day |
| Will users want it? | not a prototype — fake-door or interview (product-spec); don't build to find out | — | — |

## Card fields (all required before code)
- **Question** — one sentence ending in "?"
- **Success** — measurable: "≥ 90% of 30 sample listings parsed with correct name/address", "user picks a variant in < 5 min"
- **Kill** — the result that changes the plan: "< 70% → don't build ingest on this source"
- **Timebox** — hours; at the end you decide with what you have
- **Faked** — what is stubbed (auth, persistence, other services) so nobody mistakes it for done
- **Where** — branch `proto/<slug>`, run command

## Rules shared by every shape (after Matt Pocock's prototype skill, MIT)
1. Throwaway from day one and named as such; lives next to where the real thing will live, on the proto branch.
2. Trivial to run: one command or a double-click.
3. No persistence unless persistence is the question (then a scratch store named "PROTOTYPE, wipe me").
4. No tests, no error handling beyond "runs", no abstractions.
5. Surface the state/result after every action or variant switch.
6. Capture the answer, not the code: verdict in the card; validated logic or chosen design rewritten properly in a planned task.

## What this adds to Matt's skill
| Matt's prototype | This skill adds |
|---|---|
| logic and UI branches | tech, data, AI and flow spikes |
| question stated at the top | success + kill criteria and a timebox *before* building |
| verdict in the issue/commit | verdict wired into SPEC risks, the SPEC change log and an ADR, then `loop.sh` moves the project on |
| — | refuses to prototype demand questions (use interviews / fake doors) |
