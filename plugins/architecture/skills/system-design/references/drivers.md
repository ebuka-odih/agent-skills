# Drivers interview

Architecture follows from constraints. Collect these before any decision.

## Ask in one batch (max 6), each with a default

| # | Question | Default if the user says "defaults" |
|---|---|---|
| 1 | What does it do, and for whom? (one sentence) | — must be answered |
| 2 | Scale at launch and in 12 months: users, peak requests/sec, data size | < 10k users, < 50 rps, < 50 GB |
| 3 | Team size now and expected | 1–3 engineers |
| 4 | Hard constraints: budget, hosting, compliance (GDPR/HIPAA/PCI/SOC 2), systems to integrate | Low budget, no regulated data beyond GDPR basics |
| 5 | Downtime and data-loss tolerance | 99.5% uptime, RPO 1 h, RTO 4 h |
| 6 | Stack preference | House defaults (`defaults.md`) |

## Recover mode

Answer from evidence first, ask only gaps:
- Stack and versions: lockfiles, `composer.json`, `package.json`, `go.mod`, Dockerfiles
- Shape: top-level folders, workspace config, number of deployables
- Hosting: CI deploy steps, IaC folders, platform config files (`fly.toml`, `vercel.json`, `forge`, `serverless.yml`)
- Auth: auth packages, middleware, login routes
- Data: DB drivers, migration folders, `.env.example`

Write each inferred driver with its evidence path: `Postgres 16 — docker-compose.yml:12`.

## Rank the quality attributes

Ask the user to pick the top 3 in order. Use them to break ties in every later area.

time-to-market · security · availability · latency · cost · scalability · operability · compliance
