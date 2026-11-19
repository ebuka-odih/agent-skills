---
description: versioning picks the version from the commits, bumps every version file, writes the CHANGELOG, tags, and verifies the build reports the new version.
tags: [product]
runs: 1
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Cut a release of what's on main. There's no remote yet, so skip pushing and publishing. People run it as `node bin/cli.js`.
