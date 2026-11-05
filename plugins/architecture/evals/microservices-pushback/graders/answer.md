---
type: llm
weight: 2
---
PASS if the answer:
- recommends a modular monolith (one deployable with modules users/invoices/payments/notifications) instead of 4 microservices for this team,
- gives a reason tied to team size or launch timeline, not just "simpler",
- names a concrete condition or trigger under which a module would later be extracted into a service, AND
- mentions enforcing module boundaries (tooling, or no cross-module table access).

FAIL if it endorses starting with 4 microservices, or refuses to recommend.
