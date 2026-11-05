# Laravel / PHP

## Where things go
| Thing | Location | Notes |
|---|---|---|
| HTTP entry | `app/Http/Controllers/*Controller.php` | Thin: authorize → validate → call action → return resource |
| Validation | `app/Http/Requests/*Request.php` (Form Requests) | `authorize()` + `rules()`; never validate in controllers by hand |
| Business logic | `app/Actions/<Domain>/<Verb><Noun>.php` (single `handle()`), or module services | One use case per class |
| Authorization | `app/Policies/*Policy.php` | `$this->authorize('cancel', $booking)` |
| Output shape | `app/Http/Resources/*Resource.php` | Never return models directly from APIs |
| Background work | `app/Jobs/*` (`ShouldQueue`, idempotent, `$tries`, `backoff()`) | |
| Events | `app/Events`, `app/Listeners` | Past-tense names |
| AI | `app/Ai/Agents`, `app/Ai/Tools` | See ai-engineering `ai-stack` |
| DB | migrations + `app/Models`; scopes for reusable queries | Eager-load to avoid N+1 (`->with()`, `Model::preventLazyLoading()` in dev) |
| Modular monolith | `app/<Module>/…` or `modules/<Module>/…` per ARCHITECTURE.md | Enforce with deptrac / Pest arch tests |

## Conventions
- `declare(strict_types=1);`, typed properties and return types, `readonly` DTOs/value objects.
- Config via `config('x.y')`, never `env()` outside `config/`.
- Use enums (`enum Status: string`) instead of string constants.
- Transactions around multi-write operations: `DB::transaction(fn () => …)`.
- Dates via `now()` / `CarbonImmutable`; tests use `$this->travelTo()`.

## Commands (detected by project-commands.sh)
`vendor/bin/pint` (format) · `vendor/bin/phpstan analyse` / Larastan (types) · `php artisan test` or `vendor/bin/pest` (tests).

## Tests
Pest or PHPUnit feature tests per endpoint (`actingAs`, `assertForbidden`, `assertJsonPath`), `RefreshDatabase`, factories; `Http::fake()`, `Queue::fake()`, `Agent::fake()` for externals.

## Never
`dd()`, `dump()`, `ray()`, `var_dump()` left in code · raw `DB::statement` with interpolated input · `$guarded = []` on models that take request input.
