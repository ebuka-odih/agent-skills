# Mutation tools

## Pest 3 (`--mutate`)
```php
// tests/Unit/LateCancelFeeTest.php
covers(\App\Billing\LateCancelFee::class);   // or mutates(...) — tells Pest what to mutate

it('charges half when cancelled 119 minutes before', function () { /* ... */ });
```
```bash
vendor/bin/pest --mutate                      # mutate covered classes
vendor/bin/pest --mutate --parallel --min=80  # CI: fail below 80% score
```
Tests without `covers()`/`mutates()` aren't used for mutation — add them to the critical tests only.

## Infection (PHP, PHPUnit or Pest)
```bash
composer require --dev infection/infection
vendor/bin/infection --threads=max --min-msi=80 --min-covered-msi=90 \
  --git-diff-filter=AM --git-diff-base=origin/main     # only lines changed vs main
```
Config `infection.json5`: `source.directories`, `mutators` (`@default`), `logs.html`.

## mutmut (Python)
```toml
# pyproject.toml
[tool.mutmut]
paths_to_mutate = ["app/services/fees.py"]
tests_dir = ["tests/"]
```
```bash
mutmut run        # runs pytest against each mutant
mutmut results    # list survivors
mutmut show <id>  # see the diff of one mutant
```

## StrykerJS (TypeScript)
```bash
npm i -D @stryker-mutator/core @stryker-mutator/vitest-runner   # or jest-runner
npx stryker init
npx stryker run --incremental                                   # reuses previous results
```
`stryker.config.json`: `"mutate": ["src/features/fees/**/*.ts", "!**/*.test.ts"]`, `"thresholds": { "high": 90, "low": 70, "break": 60 }`.

## Reading a survivor
```
- if (minutesBefore >= 120) return 0;
+ if (minutesBefore > 120) return 0;      ← survived: no test at exactly 120
```
Fix: add `it('is free at exactly 120 minutes')`.
