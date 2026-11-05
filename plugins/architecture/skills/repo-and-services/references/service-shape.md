# Service shape

**Default: modular monolith** — one deployable, strict internal modules, one database with per-module table ownership.

## Decide by the strongest driver

| Driver | Shape |
|---|---|
| Team < ~10 engineers, product still finding fit | Modular monolith |
| One component scales very differently (video transcoding, ML inference) | Monolith + extract only that component as a worker/service |
| Teams block each other's deploys weekly on one module | Extract that module |
| Regulatory isolation (PCI card data, PHI) | Isolate that scope: own service + own datastore |
| Spiky, event-driven, low steady traffic | Serverless functions for those paths only |
| A different runtime is genuinely required | Separate service for that part |

## The microservice test
For each proposed service, name all three. Missing any → it's a module.
1. Owning team
2. Data it alone owns
3. Why it must deploy separately

## Costs to state when recommending services
Network failure handling · distributed tracing · contract versioning · data consistency (sagas/outbox) · local dev setup · per-service CI/CD · on-call per service.

## Extraction readiness
A module is ready to extract when the extraction is a mechanical change: it talks to others only through its public interface, owns its tables exclusively, and has its own tests. Record the trigger in ARCHITECTURE.md "Planned evolution".
