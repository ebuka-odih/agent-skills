---
name: infrastructure-as-code
description: Describe hosting and infrastructure as reviewed code — choose the platform (PaaS, Dokploy/self-hosted, Laravel Cloud/Forge, containers, Terraform/OpenTofu), write a production Dockerfile, keep platform config in the repo, plan before apply, separate state per environment, and never change production by hand. Use when the user says "deploy setup", "Dockerfile", "Terraform", "docker compose", "Dokploy", "where should we host this", "infrastructure", or when delivery-pipeline routes hosting work.
---

# Infrastructure as code

## 1. Pick the platform (record in ARCHITECTURE.md §11 + an ADR)
| Situation | Default |
|---|---|
| Laravel app, small team | Laravel Cloud or Forge (+ config in repo where supported) |
| Small app, own VPS, Docker | Dokploy / Coolify with `docker-compose.yml` or Dockerfile in repo |
| Containers, managed scaling | Fly.io / Render / Cloud Run / ECS — config file in repo |
| Multiple services, networks, managed DBs, IAM | Terraform/OpenTofu modules per environment |

## 2. Write the artifact
Production Dockerfile — [references/docker.md](references/docker.md): multi-stage, pinned base image, non-root user, no secrets in layers, health check, small image.

## 3. Keep infra in the repo
`infra/` (Terraform/OpenTofu) or platform files (`fly.toml`, `render.yaml`, `docker-compose.prod.yml`) — reviewed in PRs like code. Rules: [references/terraform.md](references/terraform.md).

## 4. Change flow
plan → review the plan in the PR → apply to staging → verify → apply to production with approval. The infra guard hook asks before `terraform apply -auto-approve`, `destroy`, and production-destructive commands.

## Hard rules
- No manual production changes ("click-ops"). If an emergency needs one, write it into code the same day.
- State is remote, locked and per environment; never commit `.tfstate` or `.tfvars` with secrets.
- Least privilege for CI deploy credentials; prefer OIDC (GitHub → cloud) over long-lived keys.
