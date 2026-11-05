---
updated: YYYY-MM-DD
---

# <Project> — Security

> Baseline status, threat models and accepted risks. Read before changing auth, input handling, uploads, webhooks, secrets or PII flows.

## Summary
- **Open gaps:** <n critical · n high · n medium · n low>
- **Last dependency audit:** <date · command · result>
- **Last full audit:** <date · tool · report location (outside repo)>

## Baseline
| Area | Control | Status | Evidence / fix | Severity | Owner |
|---|---|---|---|---|---|
| Identity | Login rate limit | in place | `routes/web.php:12` throttle:5,1 | — | — |
| Input | Webhook signatures | gap | verify Stripe-Signature in `WebhookController` | high | <name> |

## Threat models
| Feature | File | Date | Open mitigations |
|---|---|---|---|

## Accepted risks
| Risk | Why accepted | Review by |
|---|---|---|

## Secrets
Where they live · who can read them · rotation runbook link · last rotation.

## Incident contacts
<who to call; where to report a vulnerability>
