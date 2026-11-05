---
type: llm
weight: 3
---
Planted issues in InvoiceController.php:
(a) show(): no authorization — any user can read any tenant's invoice by ID (IDOR); also returns the raw model;
(b) search(): SQL injection via `$q` (and string-built tenant_id) in DB::select;
(c) update(): mass assignment via `$request->all()` (e.g. tenant_id, status, amount);
(d) stripeWebhook(): no Stripe signature/timestamp verification — anyone can mark invoices paid; no replay/dedupe.

PASS if the answer identifies all of (a), (b) and (d) and at least mentions (c), with method or line references and concrete fixes (policy/authorize, bindings, validated()/fillable, verify signature with the webhook secret). FAIL otherwise.
