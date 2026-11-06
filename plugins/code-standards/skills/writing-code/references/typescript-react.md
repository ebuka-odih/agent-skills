# TypeScript / React

UI look and consistency (tokens, shadcn + Tailwind, dashboard patterns, stories, visual/a11y tests) live in the **frontend** plugin — start with its `ui-system` skill and `docs/ui/UI.md`.

## Where things go
| Thing | Location | Notes |
|---|---|---|
| Pages/routes | `src/pages` / `src/routes` / `app/` (framework convention) | Thin: compose features |
| Feature code | `src/features/<feature>/{components,hooks,api,types}.ts(x)` | Co-locate by feature, not by file type |
| Shared UI | `src/components/ui/` (design system) | No business logic |
| API client | `src/features/<f>/api.ts` or generated from OpenAPI | Typed responses; one place per endpoint |
| Server state | TanStack Query / framework loaders | Not in global stores |
| Client state | local `useState` → context → store (Zustand) only when shared | |
| Types | `types.ts` per feature; generated API types | No `any` |

## Conventions
- `strict: true`; no `any` (use `unknown` + narrowing); no non-null `!` without a comment why.
- Components: function components, props typed, one component per file for anything reused; keep under ~150 lines.
- Effects only for syncing with external systems; derive values instead of storing them.
- Lists have stable keys (IDs, not indexes).
- Accessibility: labels on inputs, buttons are `<button>`, keyboard reachable, alt text.
- Validate external data at the boundary (Zod) before it enters typed code.

## Commands (detected by project-commands.sh)
`prettier --write` or `biome format` · `eslint` / `biome lint` · `tsc --noEmit` · `vitest run` / `jest`.

## Tests
Vitest/Jest + Testing Library: test behaviour through roles and text (`getByRole`), not implementation; MSW for network; Playwright for critical journeys.

## Never
`console.log` / `debugger` left in · `// @ts-ignore` without reason · secrets in client code (anything in the bundle is public) · `dangerouslySetInnerHTML` with untrusted content.
