---
name: ai-learnings
description: Make the AI architecture learn over time — record what each project discovers (eval results, incidents, model swaps, cost surprises, spec changes, review findings) in docs/ai/LEARNINGS.md, feed lessons back into the feature cards and AI.md, and promote lessons seen across projects into the house AI defaults with the user's approval. Use after an eval run, an AI incident or bug, a model or provider change, a spec change touching AI requirements, when the user says "remember this for next time", "what have we learned", "update the defaults", or when the session-start hook reports AI drift.
---

# AI learnings

```
project: event → LEARNINGS.md entry → change card / AI.md / eval cases
house:   same lesson in ≥ 2 projects (or obviously general) → user approves → house-defaults.md
next project: ai-design reads house-defaults.md + LEARNINGS.md before asking anything
```

## 1. Record (every time one of these happens)
| Trigger | Capture |
|---|---|
| Eval run | score change, which cases failed, model/prompt versions |
| Incident / bug | input that broke it (anonymised), impact, fix |
| Model or provider change | why, eval before → after, cost/latency change |
| Spec change touching an `R…` an AI feature serves | what changed, which F-ids are affected |
| Review finding (`ai-design` check mode) | rule broken, where |
| Cost or latency surprise | metric, cause |

Append to `docs/ai/LEARNINGS.md` using [templates/LEARNINGS.md](templates/LEARNINGS.md). One entry = one lesson, with evidence.

## 2. Apply locally — the same day
Every entry ends with an **action**: a card change, a new eval case, a config change, an AI.md decision update, or "no change — why". An entry with no action is just a diary.

## 3. Re-check against the spec
When `docs/spec/SPEC.md` version is newer than `spec_version` in AI.md: list changed requirements, mark affected features, run `ai-feature` for each, bump `spec_version`.

## 4. Promote to house defaults
Follow [references/promotion.md](references/promotion.md). Mark entries `scope: house-candidate` when the lesson isn't specific to this product. Ask the user before changing house defaults — always.

## Hard rules
- Lessons cite evidence (eval run file, incident link, log query). No evidence → `status: hunch`, not a rule.
- Project LEARNINGS override house defaults for that project; record the override and why.
- Never delete a learning; mark it `superseded by L<n>`.
