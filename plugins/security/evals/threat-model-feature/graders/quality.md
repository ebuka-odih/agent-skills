---
type: llm
weight: 4
focus: { source: file, path: docs/security/threats/photos-and-payments.md }
---
PASS only if the threat model covers ALL of:
1. Webhook spoofing: verify Stripe signature (and timestamp window) before trusting the event; replay/duplicate events handled (idempotency / event-ID dedupe).
2. Upload abuse: validate file type by content (not extension), size limit, and don't serve user files as executable/HTML (e.g. SVG/HTML, Content-Type, Content-Disposition), stored privately with random names.
3. Tenant isolation: members of another studio can't read the photos (or URLs are scoped/signed).
4. Each threat has a mitigation and a concrete proof (test name or config check), or is explicitly accepted with a reason.
5. Trust boundaries or a data-flow diagram are identified.
FAIL if any of 1–3 is missing.
