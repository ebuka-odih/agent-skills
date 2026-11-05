---
type: llm
weight: 3
---
PASS only if the answer:
1. Uses a Laravel AI SDK agent class (e.g. `php artisan make:agent … --structured`) implementing `HasStructuredOutput` with a `schema(JsonSchema $schema)` method;
2. Allows missing values (nullable fields or a "missing"/confidence field) rather than forcing invented values;
3. Does not hard-code a single model name inside the agent with no fallback — uses config/tiers or the SDK's provider failover array;
4. Shows or describes testing with `::fake(...)` (and ideally `preventStrayPrompts()`), not real API calls in tests;
5. Mentions validating/reviewing before saving, or an eval set of sample invoices.

FAIL if it uses raw HTTP/json_decode of free text, or invents SDK APIs that contradict the above.
