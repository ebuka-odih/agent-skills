# Input/output contract

## Output schema
Define the schema in code, in the language that runs the model call, and treat it as the API.

**Pydantic (FastAPI / Pydantic AI)**
```python
class InvoiceFields(BaseModel):
    vendor: str | None
    total_cents: int | None = Field(ge=0)
    currency: Literal["NGN", "USD", "EUR"] | None
    confidence: Literal["low", "medium", "high"]
    missing: list[str] = []        # fields the model could not find
```

**Laravel AI SDK**
```php
public function schema(JsonSchema $schema): array {
    return [
        'vendor' => $schema->string(),
        'total_cents' => $schema->integer()->min(0),
        'confidence' => $schema->string()->enum(['low','medium','high'])->required(),
    ];
}
```

## Rules
- Missing information is `null` + listed in `missing`, never invented.
- Include `confidence` (or probability) when the app branches on the result.
- IDs the model returns must come from the input or tool results — validate membership after the run.
- Version the schema with the prompt: `F1 v3 = prompt v3 + schema v2`.

## Invalid output
1. Schema validation fails → retry once with the validation error fed back (Pydantic AI does this on `output_type` failures).
2. Still invalid → next model in the fallback chain.
3. Still invalid → non-AI fallback + log `outcome=invalid`.

## Input contract
List each input field, its source, max size, and whether it is **trusted** (your system) or **untrusted** (user, web, email, documents). Untrusted inputs are delimited and never placed in instructions (see `ai-safety`).
