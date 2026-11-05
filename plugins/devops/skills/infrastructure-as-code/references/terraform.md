# Terraform / OpenTofu rules

```
infra/
├── modules/            # reusable: app, db, cache, bucket
├── envs/
│   ├── staging/        # main.tf calls modules; backend.tf (remote state); terraform.tfvars (no secrets)
│   └── production/
└── README.md           # how to plan/apply, who approves
```

- Remote state with locking (S3 + DynamoDB, GCS, Terraform Cloud); one state per environment.
- `terraform fmt -check`, `validate`, `tflint` and `plan` run in PR CI; the plan is posted to the PR.
- Apply staging on merge; production apply needs a manual approval (GitHub Environment protection).
- Pin provider and module versions; `.terraform.lock.hcl` committed.
- Secrets come from the cloud secret manager via data sources — never in `.tfvars` in git.
- `prevent_destroy = true` on databases, buckets with user data, DNS zones.
- Drift: scheduled `plan` job alerts when reality differs from code.
