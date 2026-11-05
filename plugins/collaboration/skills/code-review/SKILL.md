---
name: code-review
description: Review a pull request or diff — your own before asking for review, a teammate's, or an AI agent's — against the task's acceptance criteria, ARCHITECTURE.md and AI.md rules, tests and security basics; write clear labelled comments (blocking / suggestion / question / nit) and decide approve or request changes. Use when the user says "review this PR", "review my changes", "is this ready to merge", "check this diff", gives a PR URL or number, or before marking your own PR ready.
---

# Code review

## 1. Get the context first
- PR body / task: what was asked (`T<id>` → PLAN.md, `R<id>` → SPEC.md), what it claims.
- Diff: `gh pr diff <n>` or `git diff origin/main...HEAD`. Read tests first, then code.
- Rules that apply: `docs/architecture/ARCHITECTURE.md`, `docs/ai/AI.md` if AI code changed.

## 2. Check, in this order
Follow [references/checklist.md](references/checklist.md). Stop at the first blocking problem class and report it before polishing smaller things.
1. **Does it do what was asked?** Each acceptance criterion → where is it in the code and which test proves it.
2. **Is it correct?** Edge cases, errors, concurrency, data migrations.
3. **Does it fit?** Run architecture check mode (`system-design` → check-mode) and AI check mode (`ai-design` → check) on the diff.
4. **Is it safe?** Auth on new endpoints, input validation, secrets, PII.
5. **Is it tested?** New behavior has tests that would fail without the change.
6. **Is it clear?** Names, size, dead code, comments explaining *why*.

## 3. Write comments
Use the labels in [references/comments.md](references/comments.md). Every blocking comment says what's wrong, why it matters, and a concrete fix. Cite `file:line`.

## 4. Decide
| Situation | Verdict |
|---|---|
| Any blocking comment | Request changes |
| Only suggestions / nits / questions | Approve (questions answered async) |
| Can't judge (missing context, can't run it) | Comment — say what you need |

Post with `gh pr review <n> --approve | --request-changes | --comment --body-file …` only if the user asked you to post; otherwise show the review in chat.

## Reviewing an AI agent's PR
Compare its claims against evidence: the goal file, the session log (`session-report` skill), and the diff. A claim with no evidence is a blocking comment.
