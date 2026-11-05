# Module boundaries

## Rules
- A module exposes a public interface (service class, facade, or in-process events). Everything else is internal.
- No module reads or writes another module's tables. Ask through the interface.
- Dependencies point one way. Draw the graph; cycles are bugs.
- Shared kernel (`packages/shared`, `app/Support`) holds only types and pure utilities — no business rules.

## Enforce with tooling, not hope

| Stack | Tool |
|---|---|
| PHP / Laravel | deptrac (`deptrac.yaml`), or Pest arch tests (`arch()->expect('App\Billing')->not->toUse('App\Identity\Models')`) |
| TypeScript | eslint-plugin-boundaries, or Nx module-boundary tags |
| Python | import-linter |
| JVM | ArchUnit |
| Go | `internal/` packages |

Record the tool and its config path in ARCHITECTURE.md §5. CI must fail on a violation.

## Default dependency direction
```
http/ui → application (use cases) → domain → (nothing)
infrastructure → domain   (implements domain interfaces)
```
