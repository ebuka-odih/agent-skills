# Promoting a lesson to house defaults

House defaults live in this plugin: `skills/ai-design/references/house-defaults.md`. Every new project's `ai-design` run reads them first, so a promoted lesson changes how every future project is designed.

## When to propose
| Evidence | Proposed status |
|---|---|
| Seen in 1 project, clearly general (e.g. "validate JSON output against a schema") | `watch` |
| Seen in ≥ 2 projects | `prefer` |
| Seen in ≥ 2 projects **and** caused an incident or eval regression when ignored | `rule` |
| Contradicts an existing row | propose changing that row; cite both sources |

## Steps
1. Collect `house-candidate` entries from `docs/ai/LEARNINGS.md` not yet promoted.
2. Check house-defaults.md for an existing row on the same topic → upgrade its status and add this project to Source, instead of adding a duplicate.
3. Show the user each proposed row: `status · default · source (project + date)`. Ask for approval per row.
4. If approved, edit house-defaults.md:
   - Find the plugin root: `$CLAUDE_PLUGIN_ROOT`, or `find ~/.claude/plugins -path '*ai-engineering*' -name house-defaults.md`.
   - If that directory is a git checkout of the skills repo (`git -C <root> rev-parse` succeeds): edit, bump the plugin version, add a CHANGELOG line, and tell the user to commit and push (or do it if they asked).
   - If not (installed from GitHub cache): write the proposed rows to `docs/ai/house-defaults.patch.md` in the project and tell the user to apply them in the skills repo.
5. Mark the LEARNINGS entries `promoted: <date>`.

## Never
- Promote product-specific facts (prices, model names that only fit one domain, customer names).
- Put project paths, secrets or customer data into house defaults — the skills repo may be public.
