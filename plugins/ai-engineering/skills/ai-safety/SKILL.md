---
name: ai-safety
description: Threat-model and guard AI features — prompt injection from user, web, email and document content; tool and agent permissions; data leaks across users or tenants; PII and data residency; harmful or off-brand output; abuse and cost attacks; when a human must review. Use when designing or reviewing any AI feature, agent or chatbot, when the user asks "is this AI feature safe", "prompt injection", "can the agent do X", "PII to OpenAI", or when ai-feature records safety.
---

# AI safety

## Steps
1. List the feature's **untrusted inputs** (anything a user, website, email, file or third party wrote).
2. List what the feature can **do** (read data, write data, send, pay, browse, run code).
3. Walk [references/threats.md](references/threats.md) for that combination. Each threat: control chosen, or "accepted — why".
4. Decide **human review**: required when a wrong output costs money, legal exposure, safety, or is sent to someone outside the user.
5. Decide **PII**: which fields go to which provider/region; redact or pseudonymise the rest. Record in AI.md.
6. Add adversarial cases to the eval set (`ai-evals`).

## Controls that always apply
- Instructions and untrusted content are separated: content goes in delimited blocks, and the instructions say it's data, written by strangers, never commands.
- The model never decides authorization. Tenant/user scope comes from server-side deps, not model arguments.
- Writes, sends, payments and deletes go through an approval step the user sees (confirm card / `Approvable` tool).
- Output that reaches HTML is escaped; output used in SQL/shell/URLs is validated, never executed raw.
- Per-user and per-tenant rate limits and spend caps on AI endpoints.

## Hard rules
- An agent with both untrusted input **and** a write/send tool needs approval on that tool. No exceptions.
- No provider keys in browsers or mobile apps.
- Log tool calls and approvals with who approved.
