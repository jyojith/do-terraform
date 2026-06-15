# BizQuery (dev)

The BizQuery platform, deployed by Argo CD from this directory. One image
(`ghcr.io/bizquery/bizquery-platform`) runs as two Deployments — **api** (uvicorn) and **worker**
(procrastinate) — against an in-cluster **Postgres+pgvector**, served at **https://app.bizquery.dev**
via Traefik (Let's Encrypt `letsencrypt` resolver). The image self-migrates on boot (`init-db` is
advisory-locked), so there's no migration job.

## Secrets

**`bizquery-secrets` is provisioned by Terraform** (the `argocd` stack — `bizquery-secrets.tf`),
which also creates the `bizquery` namespace so the Secret exists before pods start. You only supply
the DigitalOcean Gradient AI model access key; the DB password, session secret, bootstrap key, and
admin password are auto-generated and kept in Terraform state.

```sh
# .env (repo root), then: set -a && source .env && set +a
TF_VAR_do_model_access_key=<DO Gradient AI model access key>   # drives chat + embeddings
```

Retrieve the generated logins after apply:

```sh
terragrunt --terragrunt-working-dir environments/dev/argocd output -raw bizquery_admin_password
terragrunt --terragrunt-working-dir environments/dev/argocd output -raw bizquery_bootstrap_api_key
```

**Image pull secret** (still manual — the GHCR package is private; skip if you make it public).
Create it *after* `terragrunt apply` (the namespace already exists by then):

```sh
kubectl -n bizquery create secret docker-registry ghcr-pull \
  --docker-server=ghcr.io \
  --docker-username=<github-username> \
  --docker-password=<PAT-with-read:packages>
```

(Non-secret config — models, storage path, admin email — lives in `configmap.yaml`. Models point at
DigitalOcean Gradient AI: chat `openai-gpt-oss-20b`, embeddings `Qwen3-Embedding-0.6B`.)

## Deploy

1. Add the DNS record: in `environments/dev/env.hcl` the `app` entry is already in `dns_records`;
   apply the dns stack so `app.bizquery.dev` points at Traefik's LB:
   `cd environments/dev/dns && terragrunt apply` (or `./scripts/tg.sh apply dns`).
2. Push this directory to `main` of `jyojith/do-terraform`. The `bizquery-apps` ApplicationSet
   already lists `bizquery`, so Argo CD creates the app and syncs (auto self-heal + prune).
3. Watch it: `kubectl -n bizquery get pods,ingress` and the Argo CD UI. First TLS issuance takes a
   minute.

## Heads-up: node size

The dev cluster is a single `s-1vcpu-2gb` node shared with Argo CD, Traefik, and system pods. api +
worker + Postgres on top of that is tight and may schedule slowly or OOM under load. For real use,
bump `node_size` (e.g. `s-2vcpu-4gb`) in `environments/dev/env.hcl`, and/or move the database to a
DO Managed Postgres (pgvector-capable) and delete `postgres.yaml`, pointing `BQP_DATABASE_URL` at it.
