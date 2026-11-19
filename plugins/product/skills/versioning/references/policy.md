# Release policy and version rules

## When to release — `release:` in PLAN.md front matter
| Policy | Release when | Fits | Session hook says "Release due" when |
|---|---|---|---|
| `per-feature` | every merged `feat` (fixes ride along with the next one, or ship alone when users are hurt) | apps users install themselves (desktop, CLI, mobile beta), solo products shipped daily | an unreleased `feat` commit exists |
| `per-milestone` (default) | the milestone's demo passes | web apps with staging → production, team projects | a milestone is `done` but not `released` |
| `manual` | the user says so | client work, app-store review cycles, regulated releases | never; the status line still shows unreleased commits |

The user picks it once 🧑 — offer it in the report of the first release; don't hold that release for it. Write it in PLAN.md, not in agent memory, so every session and every agent follows it:
```yaml
---
spec_version: 1
release: per-feature   # per-feature | per-milestone | manual
updated: 2026-11-19
---
```

## Bump rules (Conventional Commits since the last tag)
| Commits contain | 0.x | ≥ 1.0 |
|---|---|---|
| `type!:` or `BREAKING CHANGE:` | minor | major |
| `feat:` | minor | minor |
| only `fix:`, `perf:`, `refactor:`, `docs:`… | patch | patch |
| only `chore(release)` / nothing | no release | no release |

1.0.0 is a product decision (public launch, stable data format), never an automatic bump: `version.sh bump 1.0.0`.

## Where the version lives
| Stack | File(s) `version.sh` keeps in sync | Shown to users |
|---|---|---|
| Node / TS | `package.json` | footer, `/version` route, `--version` |
| Python | `pyproject.toml` (`[project]` or `[tool.poetry]`) | `/version`, `--version` |
| PHP / Laravel | `composer.json` `version` or `VERSION` (config reads it) | footer, `/version` |
| Rust | `Cargo.toml` `[package]` | `--version` |
| Apple apps | `Info.plist` `CFBundleShortVersionString` (+ integer `CFBundleVersion` +1) | About window, splash |
| Anything else | `VERSION` | wherever the app prints it |
| Several files (web + app) | pass each with `--file`, or `VERSION_FILES="package.json App/Info.plist"` | — |

The version must be **visible in the running product** (About, footer, `/version`, `--version`). That is what makes step 7 checkable and "I don't see the changes" answerable in one look.

## CHANGELOG
`version.sh bump` writes a section grouped Breaking / Features / Fixes / Other from commit subjects. Rewrite it for users: what they can do now, what was fixed, what to do if something breaks. Keep internal refactors out unless they change behaviour.
