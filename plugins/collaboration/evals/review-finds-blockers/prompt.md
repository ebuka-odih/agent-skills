---
description: Reviews a PR diff against its task and labels blocking issues with file:line.
tags: [collaboration]
runs: 1
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---
Review the pull request in the `resources` directory: the description is `PR.md` and the diff is `changes.diff`. Tell me whether it's ready to merge. Answer in chat only.
