# Adopt an existing project

Goal: get the contract files and a measured baseline **without changing behaviour**, so every later feature or fix runs through the normal loop.

## Steps (one PR, docs only)
1. **Recover the spec** — `product:product-spec` in *Recover* mode: read routes, pages, models, tests, README → `docs/spec/SPEC.md` with requirements marked `status: done` for what exists today, plus known gaps as open requirements. 🧑 confirm the non-goals and priorities.
2. **Recover the architecture** — `architecture:system-design` in *Check* mode → `docs/architecture/ARCHITECTURE.md` describing what *is* (components, data, deploy), with "drift" notes where code fights the intended design.
3. **Baseline** — run every scanner that applies and write the numbers into `docs/project/BASELINE.md` (template: `templates/BASELINE.md`):

| Area | Command | Record |
|---|---|---|
| Tests | the project's test command; `testing` test-plan.sh | pass/fail counts, untested critical code |
| Code | `code-standards` leftover-scan.sh | debug leftovers, TODOs without tickets |
| Security | `security` security-scan.sh | findings by severity |
| Delivery | `devops` devops-scan.sh | CI present, deploy, environments |
| UI | `frontend` ui-scan.sh | raw colours, arbitrary values, layers |
| SEO (public sites) | `seo` seo-crawl.sh <url> | critical/high findings |
| Speed | `seo` page-speed.sh <url> | LCP/INP/CLS p75 |
| AI | `ai-engineering` ai-context hook / AI.md | features without evals |

4. **Missing design docs** — let `loop.sh` ask for UI.md / AI.md / SEO.md / SECURITY.md / DELIVERY.md; write them *as-is* first, target state second.
5. **Plan** — `product:project-plan`: M0 = "fix the baseline's critical findings", M1… = the next features. 🧑 order them.
6. Log: `loop.sh log adopt "SPEC, ARCHITECTURE, BASELINE recovered · next: project-plan"`.

## Rules
- Adoption changes docs only; fixes found by the baseline become M0 tasks.
- Re-run the baseline after each milestone; the delta is the progress report.
