---
description: Sets up mutation testing for a critical Laravel billing rule with Pest --mutate, scoped and gated, and strengthens weak tests.
tags: [testing]
runs: 1
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---
Set up mutation testing for our billing rule (app/Billing/LateCancelFee.php) and improve the tests so mutants don't survive. Don't install anything or run commands — edit the files and tell me the commands to run locally and in CI.
