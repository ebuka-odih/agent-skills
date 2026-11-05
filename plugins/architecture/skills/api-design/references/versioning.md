# Contracts, versioning, webhooks

## Contract source of truth
- REST: `openapi.yaml` in the repo (or generated from code and committed). Generate clients/types from it.
- GraphQL: schema file, with breaking-change check in CI (graphql-inspector).
- gRPC: `.proto` files, `buf breaking` in CI.

## Versioning
- Public API: version in the path (`/v1/`) or a date header (`Api-Version: 2026-11-01`). Pick one, record it.
- Internal/first-party only: no version prefix; evolve additively and deploy client + server together.

**Additive (safe):** new endpoint, new optional field, new enum value clients are told to tolerate.
**Breaking (new version):** removing/renaming a field, changing a type, new required input, changed meaning.

## Deprecation
- Announce with `Deprecation` and `Sunset` headers + changelog entry.
- Minimum notice: 6 months for public APIs, one release cycle for internal.
- Measure usage of deprecated endpoints before removing.

## Webhooks
- **Outgoing:** sign payloads (HMAC-SHA256 with timestamp), retry with backoff for 24–72 h, include event ID for dedupe, let consumers replay.
- **Incoming:** verify signature and timestamp window before parsing, respond 2xx fast and process on a queue, dedupe by event ID.
