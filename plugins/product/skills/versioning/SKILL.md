---
name: versioning
description: Version and ship a build so the user can see it — the next version number from the commits (semver), every version file kept in sync (package.json, pyproject.toml, Cargo.toml, composer.json, Info.plist, VERSION), a CHANGELOG section, an annotated tag, the release published, then a check that the copy the user actually runs reports the new version. Use when the user says "release", "ship it", "cut a release", "bump the version", "tag it", "publish a new build", "commit and release", "why don't I see the changes", "what version is this", when a milestone is done, or when the session-start hook says "Release due".
---

# Versioning — every release has a number, a tag, a changelog and a proof

One script does the mechanics: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/version.sh" <command>`. Run it from the project root.

## Steps
| # | Do | Command / reference |
|---|---|---|
| 1 | **Where are we** — version, last tag, unreleased commits, suggested next version | `version.sh status` |
| 2 | **Is a release due?** The user asked for one → yes, go on. Otherwise read `release:` in PLAN.md front matter (`per-feature` · `per-milestone` · `manual`). No policy yet → release anyway when asked, and offer the policy in the final report — never stop to ask before releasing | [references/policy.md](references/policy.md) |
| 3 | **Gate** — tests green, working tree clean (commit the work first, Conventional Commits) | the project's test command |
| 4 | **Bump** — writes every version file + a CHANGELOG section from the commits; edit the section into plain words for users | `version.sh bump` (or `bump minor`, `bump 1.0.0`) |
| 5 | **Commit + tag** — `chore(release): vX.Y.Z`, then an annotated tag | `git commit -am "chore(release): vX.Y.Z"` · `version.sh tag` |
| 6 | **Publish** — push branch and tag; run the project's release script/CI (GitHub Release, deploy, store upload). No remote or the user said skip → say so, and still do step 7 on the local build | `git push origin HEAD vX.Y.Z` |
| 7 | **See it** — the copy the user runs reports the new version (installed app, deployed URL, CLI) | `version.sh verify --app/--url/--cmd` · [references/see-it.md](references/see-it.md) |
| 8 | **Record** — milestone released in PLAN.md; blocked tasks re-checked | `plan.sh released M4 vX.Y.Z` |

## Output
- Version files agree (`version.sh check` passes), `CHANGELOG.md` has a section for the version, tag `vX.Y.Z` on the release commit.
- The release is published and **verified where the user looks** — evidence line: `✔ /Applications/App.app reports 0.15.0`.
- PLAN.md: `released: vX.Y.Z · date` under the milestone + a progress-log line.
- Report: `v0.15.0 released (3 feat, 2 fix) · installed on your Mac · next: <next task>`.

## Hard rules
- The version comes from the commits (`feat` → minor, `fix` → patch, `!`/BREAKING → major; 0.x stays 0.x until the user decides 1.0). Never pick a number by feel.
- One source of truth: bump with `version.sh`, never by hand in one file — the others drift.
- No tag without a commit, no release without a tag, no tag that skips the CHANGELOG.
- Milestones don't carry version numbers in their names; the number is recorded when the milestone ships.
- A release is not done until step 7 passes. "Published" is not "the user has it".
- Releasing is outward-facing: follow the project's release policy; with `manual`, ask before publishing.
- Monorepo / several products: `--path <dir> --prefix <name>-` per product (tags `api-v1.2.0`).

## Hand-off (project loop)
`bash <product plugin>/scripts/loop.sh log release "vX.Y.Z released, verified on <where> · next: <skill>"` then `loop.sh next`.
