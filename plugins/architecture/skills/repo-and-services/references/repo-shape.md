# Repo shape: monorepo vs polyrepo

**Default: monorepo.** Pick polyrepo only when a row below says so.

| Driver | Points to |
|---|---|
| One team, or teams that ship together | Monorepo |
| Frontend and backend share types/contracts | Monorepo |
| Changes often span app + library atomically | Monorepo |
| Separate orgs/vendors own parts and need separate access control | Polyrepo |
| Parts have independent owners **and** release cycles | Polyrepo |
| Toolchains that fight in one CI (firmware + web) | Polyrepo |
| One part is open source, the rest private | Polyrepo for that part |

## Monorepo must-haves
- Workspace tool: pnpm/npm workspaces, Turborepo, Nx, Composer path repositories, Go workspaces
- Affected-only CI (Turborepo/Nx `affected`, or path filters)
- `CODEOWNERS` per top-level folder
- Boundary lint rules (see `boundaries.md`)

Layout:
```
apps/        deployables: web, api, worker, mobile
packages/    shared libraries: ui, config, types, sdk
infra/       IaC
docs/architecture/
```

## Polyrepo must-haves
- Versioned contracts: published packages or a schema registry
- A template repo so every repo gets identical CI, lint, and PR rules
- One index (README or catalog) listing every repo and its owner
