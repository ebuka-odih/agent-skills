---
type: llm
weight: 3
focus: { source: file, path: docs/architecture/ARCHITECTURE.md }
---
PASS only if ALL of these hold:
1. Service shape is a modular monolith (or monolith), not microservices, and the reason refers to the small team / stage.
2. Authentication is decided (not left open): a mechanism for the web client AND a different or explicitly stated mechanism for the mobile app.
3. Multi-tenancy is addressed: studios are isolated (tenant_id scoping, RLS, or similar) and enforcement is described.
4. Stripe is listed as an external dependency, with webhooks or a failure/fallback note.
5. GDPR / EU data is mentioned somewhere (retention, deletion, residency, or PII).
6. Assumed values are visibly labelled as defaults/assumptions rather than stated as user requirements.

FAIL if any item is missing, or if the document is mostly empty template placeholders like "<one sentence>".
