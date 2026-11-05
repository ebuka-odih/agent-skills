# Choosing stores

## Primary database
**Default: PostgreSQL.** Relational, transactional, JSONB for flexible fields, full-text search, strong ecosystem.

| Driver | Consider instead |
|---|---|
| Existing team expertise / hosting is MySQL-only | MySQL / MariaDB |
| Embedded, single-node, edge, or tiny app | SQLite (with Litestream/LiteFS for backups) |
| Global multi-region writes are a hard requirement | Distributed SQL (CockroachDB, Spanner, Aurora DSQL) |
| Pure key-value at massive scale, access patterns known up front | DynamoDB |

## Extra stores — add only with a reason

| Store | Add when | Before adding, try |
|---|---|---|
| Cache (Redis/Valkey) | Measured hot reads, sessions, rate limits, queues | Indexes, query fixes |
| Search (Meilisearch, Typesense, OpenSearch) | Typo-tolerance, facets, or Postgres FTS p95 too slow | Postgres FTS + trigram |
| Object storage (S3-compatible) | Any user files or large blobs | — always; never blobs in the DB |
| Analytics (ClickHouse, BigQuery, warehouse) | Heavy aggregations hurting the OLTP DB | Read replica, materialized views |
| Vector (pgvector first) | Embedding search | pgvector in the primary DB |

## Read-scaling order
indexes → query fixes → cache → read replicas → partitioning → split stores
