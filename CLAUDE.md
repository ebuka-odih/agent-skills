# Authoring rules for this repo

This repo is a Claude Code plugin marketplace. Structure is three levels:

```
plugins/<domain>/.claude-plugin/plugin.json
plugins/<domain>/skills/<skill>/SKILL.md
plugins/<domain>/skills/<skill>/references/<topic>.md   (+ templates/)
```

## Rules
1. **One domain = one plugin.** Add it to `.claude-plugin/marketplace.json`.
2. **One job = one skill.** Each domain has one orchestrator skill that lists its siblings in a tree and a hand-off table.
3. **SKILL.md is short** (≤ ~80 lines): frontmatter, a step table pointing to reference files, the output it produces, hard rules. No long checklists.
4. **References are decision tables**, one topic per file, loaded only by the step that needs them.
5. **`description` says when to trigger**, using phrases a user would type.
6. **ARCHITECTURE.md is the shared contract.** Only `architecture` writes it; every other domain reads it first.
7. **House preferences live in `defaults.md`** (one per domain). Sibling skills point to it by relative path.
8. **Third-party skills** go in `UPSTREAM.md` after reading every file. Prefer delegating to them over copying.
9. **Every skill ships with evals** in `plugins/<domain>/evals/<case>/` (prompt.md + graders/). At least one case per skill: does it fire, does it produce the promised output.
10. **Every hook script ships with tests** in `plugins/<domain>/tests/run.sh`.
11. **Every change:** bump `version` in the plugin's `plugin.json` and its entry in `marketplace.json`, add a `CHANGELOG.md` line, run `claude plugin validate plugins/<domain>`, the domain's `tests/run.sh`, and its evals.
