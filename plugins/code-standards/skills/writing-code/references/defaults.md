# Code house defaults

Edit to change the house style. Project `AGENTS.md` / `CLAUDE.md` overrides these.

| Topic | Default |
|---|---|
| Function size | ≤ ~40 lines; > 60 → split |
| File size | ≤ ~400 lines; > 800 → split by responsibility |
| Nesting | ≤ 3 levels; use early returns |
| Parameters | ≤ 4; more → a typed object/DTO |
| Types | Strict everywhere: PHP `declare(strict_types=1)` + typed props/returns; Python type hints + mypy/pyright; TS `strict: true` |
| Nulls | Explicit: `?Type` / `X | None` / `T | null`; never return mixed "false or value" |
| Money | Integer minor units + currency; never floats |
| Time | UTC in storage; convert at the edge; inject the clock in tests |
| IDs | UUIDv7/ULID for public IDs (see architecture data-design) |
| Config | Env → typed config object; never read env deep in business code |
| Logging | Structured (key/value), with request/tenant IDs; no PII |
| Comments | Explain *why*; the code says *what* |
| Dependencies | Prefer the standard library and what's already installed |
| Formatting | The project's formatter decides; never hand-format against it |
| Dead code | Delete it; git remembers |
