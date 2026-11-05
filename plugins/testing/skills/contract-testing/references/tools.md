# Contract tools

## OpenAPI breaking-change diff (oasdiff)
```bash
git show origin/main:openapi.yaml > /tmp/base.yaml
oasdiff breaking /tmp/base.yaml openapi.yaml --fail-on ERR
```
GitHub Action: `oasdiff/oasdiff-action/breaking@<sha>` with `base` and `revision`.
FastAPI: export first — `python -c "import json; from app.main import app; print(json.dumps(app.openapi()))" > openapi.json`.

## Schemathesis (fuzz against the schema)
```bash
uvx schemathesis run http://localhost:8000/openapi.json --checks all
```
Finds 5xx, responses not matching the schema, missing validation. Run against a local server with a seeded test DB and test credentials.

## Pact (consumer-driven)
- Consumer (e.g. web or mobile client) writes a test describing the request it makes and the fields it needs → generates a pact file.
- Provider CI replays pacts against the real API (`pact-provider-verifier` / language verifier).
- Share pacts via a Pact Broker or as CI artifacts. Use only when consumer and provider deploy independently.

## GraphQL / gRPC
`graphql-inspector diff old.graphql new.graphql` · `buf breaking --against '.git#branch=main'`.
