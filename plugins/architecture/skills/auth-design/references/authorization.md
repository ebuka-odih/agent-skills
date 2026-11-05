# Authorization — what may you do

## Pick the model by the shape of the rules
| Rules look like | Model | Tools |
|---|---|---|
| Fixed roles: admin, editor, viewer | RBAC | Framework policies/gates, spatie/laravel-permission, CASL |
| Depend on attributes: plan, region, department, time | ABAC / policy engine | Policy classes, OPA, Cedar |
| Follow relationships: owner, team member, shared-with | ReBAC | OpenFGA, SpiceDB, Oso |

Start with RBAC. Move to ReBAC when sharing/ownership rules appear — record the trigger.

## Enforcement
- **One** named enforcement layer (policy classes, middleware + policy, or a central authz service). Write its name in the doc.
- Deny by default. Routes without a declared permission fail a test.
- Check the object, not just the role: "can this user edit *this* invoice".
- Never trust client-sent role, tenant, or owner IDs.

## Admin and support access
- Impersonation is explicit, time-limited, shown in the UI, and audited.
- Admin actions require MFA in the current session.

## Audit
Log to an append-only audit log: authz denials, role/permission changes, impersonation start/stop, admin actions. Fields: actor, target, action, result, timestamp, request ID.
