---
id: F<n>
status: proposed   # proposed | building | live | retired
serves: R<n>
owner: <name>
prompt_version: v1
schema_version: v1
---

# F<n> — <feature name>

**Job:** <one verb + object>  ·  **Pattern:** <extraction | classification | … >  ·  **Tier:** <fast | standard | smart>

## Why AI (not rules)
<what a deterministic approach can't do here>

## Contract
**Input:** | field | source | trusted? | max size |
**Output schema:** <Pydantic model / JsonSchema, or path to it>
**Invalid output →** retry once with error → fallback model → non-AI fallback: <what the user sees>

## Context
<direct / RAG (index, top-k, rerank) / tools (list with read|write)>

## Prompt
Location: <path> · version: v1 · untrusted inputs delimited as: <how>

## Execution and budget
Mode: <sync | stream | queued> · timeout: <s> · p95 target: <s> · cost/call: <$> · monthly ceiling: <$>

## Safety
Wrong-answer cost: <low | money | legal | safety> · human review: <where> · PII sent: <fields, or none>

## Evals
Set: `evals/ai/F<n>/` · cases: <n> · graders: <schema, exact, judge> · threshold: <x%> · last run: <date, score>

## Changes
| Date | Change | Eval before → after |
|---|---|---|
