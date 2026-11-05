---
name: contract-testing
description: Keep APIs compatible between producers and consumers — diff the OpenAPI/GraphQL/proto contract in CI to block breaking changes, fuzz endpoints against their schema (Schemathesis), and use consumer-driven contracts (Pact) between services or teams. Use when changing a public or partner API, a service another service calls, a mobile app's backend, or a webhook payload; when the user says "contract test", "did I break the API", "OpenAPI diff", "Pact", "schema fuzzing"; or when test-strategy routes an API change.
---

# Contract testing

## Pick the level
| Situation | Technique | Tool |
|---|---|---|
| Any API with a committed contract file | **Breaking-change diff** on every PR | `oasdiff breaking base.yaml head.yaml` (OpenAPI) · `graphql-inspector diff` · `buf breaking` |
| Endpoints whose implementation may not match the schema | **Schema-based fuzzing** | Schemathesis: `schemathesis run http://localhost:8000/openapi.json` |
| Two services/teams, consumer needs specific fields | **Consumer-driven contracts** | Pact (consumer test publishes pact → provider verifies in its CI) |
| Mobile app clients you can't force-upgrade | Diff + versioning rule from architecture `api-design` | — |

Details and CI snippets: [references/tools.md](references/tools.md).

## Steps
1. Make sure the contract is in the repo and generated/checked against code (FastAPI exports OpenAPI; Laravel via Scramble/l5-swagger or a hand-kept `openapi.yaml`).
2. Add the diff check to PR CI against `origin/main`'s contract. Breaking change → fails, unless the PR bumps the API version per `api-design` versioning rules.
3. Run Schemathesis against a local/test instance for changed endpoints; fix 5xx and schema mismatches.
4. For service-to-service calls owned by different teams: add Pact consumer tests next to the client code; provider verifies in CI.

## Hard rules
- The contract file is the source of truth; code drifting from it fails CI.
- Fuzz only local/test instances — never production or third-party APIs.
- A breaking change ships only with a new version or a deprecation window.
