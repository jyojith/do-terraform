# Agent notes (do-terraform)

Context for AI coding agents working in this repository.

## What this repo does

- **DigitalOcean Kubernetes (DOKS)** plus **Traefik** (Helm), **ACME / Let’s Encrypt** via **DNS-01** (DigitalOcean API), **DO DNS A records** toward Traefik’s LoadBalancer IP, and **Argo CD** (GitOps).
- **No cert-manager** — TLS is Traefik’s built-in ACME (`certResolvers` / resolver name **`letsencrypt`**).

## Layout (do not confuse these)

| Path | Role |
|------|------|
| `environments/dev/*/terragrunt.hcl` | Terragrunt only: `terraform { source = "${get_repo_root()}/terraform/stacks/..." }`, `dependency`, `inputs`, generated `*.module.tf` (literal module `source` paths) + `providers.generated.tf` where needed |
| `terraform/stacks/<stack>/` | Terraform **root modules** (the `.tf` files). Referenced by Terragrunt; not duplicated under `environments/` |
| `modules/` | Shared Terraform modules consumed by stacks (paths expanded via Terragrunt `generate` because module `source` cannot use `local.*`) |
| `k8s/apps/dev/` | Sample manifests; Argo CD sync path comes from `environments/dev/env.hcl` (`manifests_path`) |

## Dependency order

`doks` → `traefik` → `dns` → `argocd`.  
Check with: `cd environments/dev && terragrunt graph-dependencies` or `./scripts/tg.sh graph`.

## Secrets and env

- **`TF_VAR_do_token`** or **`DO_TOKEN`**: DigitalOcean token (Terraform provider + Traefik ACME DNS challenge via secret → **`DO_AUTH_TOKEN`** in the Traefik pod).
- **`TF_VAR_argocd_admin_password_hash`**: Argo CD admin (bcrypt).
- Non-secret defaults: `environments/dev/env.hcl` (e.g. `domain_name`, `email` for ACME).
- Copy **`.env.example`** → **`.env`** (gitignored); load with `set -a && source .env && set +a`.

## Commands agents should use

- Validate all stacks:  
  `cd environments/dev && export TF_VAR_do_token=… TF_VAR_argocd_admin_password_hash=… && terragrunt run-all validate`  
  (or `./scripts/tg.sh validate-all` with env set).
- Format: `make tg-fmt` (Terraform + Terragrunt HCL).
- Cache reset: `./scripts/tg.sh clean-cache` if module paths or generated files behave oddly after refactors.

## Conventions when editing

- **Helm provider v3** uses `kubernetes = { ... }` (map), not a nested `kubernetes { }` block in generated providers.
- **Terragrunt cache**: child modules use `generate` blocks that write absolute `source` paths (`get_repo_root()/modules/...`); Terraform forbids `local`/variable interpolation in `module.source`.
- **App TLS**: use Traefik annotations (e.g. `traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt`); do not reference removed cert-manager secrets.
- Prefer **minimal, focused diffs**; match existing naming and structure in `modules/` and `terraform/stacks/`.
- **Do not commit** `.env`, `.terragrunt-cache`, or `terraform.tfstate*`.

## Docs

- Human-oriented overview: **`README.md`**.
