---
type: llm
weight: 3
---
PASS if the final message:
1. names Cloudflare's security-audit skill (cloudflare/security-audit-skill) as the tool for the full audit;
2. asks the user for permission before installing it (shows the install command, does not claim to have installed it);
3. says audit output goes outside the repository (e.g. ~/security-audit-skill/<repo>/…) or must not be committed;
4. mentions full-audit vs guidance mode, or a profile (quick/standard/deep), or the sandbox requirement.
FAIL if it starts auditing ad hoc without mentioning the skill, or installs it without asking.
