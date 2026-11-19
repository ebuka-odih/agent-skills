---
type: llm
weight: 3
---
Since tag v0.3.0 the repo has one `fix:` commit and one `feat(cli):` commit, so the correct next version is 0.4.0 (a minor bump; still 0.x).

PASS if the final message says the release is 0.4.0 and ties the number to the feat commit (not chosen by feel), says a tag v0.4.0 was created on a release commit, AND shows that the build reports the new version (it ran `node bin/cli.js --version` or equivalent and saw 0.4.0). It must not claim anything was pushed or published.
FAIL if it picks 1.0.0 or 0.3.1, skips the tag, or claims a push/publish happened.
