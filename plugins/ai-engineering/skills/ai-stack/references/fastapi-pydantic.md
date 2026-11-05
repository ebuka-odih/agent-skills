# FastAPI + Pydantic AI

## Layout
```
backend/app/
├── ai/
│   ├── tiers.py          # tier → model chain, from settings/env
│   ├── calls.py          # run wrapper: timeout, failover, usage logging, outcome
│   ├── prompts/          # <feature>.v<n>.md, loaded by version
│   └── features/
│       └── f1_invoice/   # agent.py (Agent + tools), schema.py (BaseModel), fallback.py
├── api/routes/           # thin: validate request → call feature → return/stream
└── workers/              # queued AI jobs (arq / database queue)
evals/ai/F1/              # cases + runner
```

## Agent
```python
from pydantic_ai import Agent, RunContext

agent = Agent(
    tier_model("standard"),            # resolves to a provider:model or fallback chain
    output_type=InvoiceFields,         # Pydantic BaseModel → validated, retried on failure
    deps_type=Deps,                    # db session, tenant, user — never from model args
    instructions=load_prompt("f1_invoice", version=PROMPT_VERSION),
)

@agent.tool
async def lookup_vendor(ctx: RunContext[Deps], name: str) -> list[VendorRef]:
    """Find vendors by name in the current tenant."""
    return await ctx.deps.vendors.search(name, tenant=ctx.deps.tenant_id)

result = await agent.run(user_text, deps=deps)
fields: InvoiceFields = result.output
```

## Streaming to the UI
SSE endpoint emitting `status`, `tool_call`, `tool_result`, `result`, `error` events (pattern used in both seed projects).

## Fallback
Ordered model chain per tier from config; hand over on 402/429/5xx/timeout/invalid output; then the feature's non-AI fallback. Pydantic AI provides a fallback-model capability; a custom loop is fine when output modes differ per provider.

## Testing
```python
from pydantic_ai import models
from pydantic_ai.models.test import TestModel
from pydantic_ai.models.function import FunctionModel

models.ALLOW_MODEL_REQUESTS = False           # in conftest.py

def test_extract():
    with agent.override(model=TestModel()):
        ...
```
Use `FunctionModel` to script tool calls; `capture_run_messages()` to assert on the exchange.

## Observability
`logfire.configure(); logfire.instrument_pydantic_ai()` for traces, plus a usage table row per run (see ai-ops).

## Avoid
- `response_format={"type": "json_object"}` + `json.loads` with no schema → use `output_type`.
- Wrapping `pydantic_ai` imports in try/except that silently disables features.
- 6,000-line modules mixing prompts, parsing and HTTP — one folder per feature.
