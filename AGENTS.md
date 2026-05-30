# Agent notes (do-terraform)

Context for AI coding agents working in this repository.

## What this repo does

- **DigitalOcean Kubernetes (DOKS)** plus **Traefik** (Helm), **ACME / Let’s Encrypt** via **DNS-01** (DigitalOcean API), **DO DNS A records** toward Traefik’s LoadBalancer IP, and **Argo CD** (GitOps).
- **No cert-manager** — TLS is Traefik’s built-in ACME (`certResolvers` / resolver name **`letsencrypt`**).
- Intended operating model: **Terraform/Terragrunt bootstraps platform infrastructure**; **Argo CD manages Kubernetes workloads** from Git; **Traefik exposes services** with ACME-managed TLS.

## Layout (do not confuse these)

| Path | Role |
|------|------|
| `environments/dev/*/terragrunt.hcl` | Terragrunt only: `terraform { source = "${get_repo_root()}/terraform/stacks/..." }`, `dependency`, `inputs`, generated `*.module.tf` (literal module `source` paths), generated backend config |
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
- Copy **`.env.example`** → **`.env`** (gitignored); load with `set -a && source .env && set +a`. **`./scripts/tg.sh`** can fill `TF_VAR_do_token` from the GitHub repository secret **`DO_TOKEN`** via `gh secret get DO_TOKEN` when the vars are empty, or when **`TG_DO_TOKEN_FROM_GITHUB=1`** (same secret name as **`terragrunt-apply.yml`**).
- Ignored Terragrunt debug/rendered files can contain tokens and kubeconfig material; treat `terragrunt-debug.tfvars.json`, `terragrunt_rendered.json`, `.env`, and `terraform.tfstate*` as sensitive local artifacts.

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
- **Traefik ACME**: default to Let's Encrypt production. Only add a staging `caServer` temporarily when testing certificate issuance.
- **Kubernetes apps**: prefer adding application workloads under the Argo CD sync path (`k8s/apps/dev`) instead of Terraform-managed Kubernetes resources. Terraform should own cluster infrastructure and bootstrap components.
- **Domains**: environment defaults live in `environments/dev/env.hcl`; add public service hostnames to `dns_records` so Terraform points them at Traefik’s LoadBalancer IP.
- **Secrets in apps**: current decision is native Kubernetes Secrets. Argo CD may manage manifests that reference/mount expected Secret names, but do not commit raw secret values. Manual dev-only Secrets are acceptable for now; future production direction is External Secrets Operator with a backing provider such as Vault or another supported secret store.
- Prefer **minimal, focused diffs**; match existing naming and structure in `modules/` and `terraform/stacks/`.
- **Do not commit** `.env`, `.terragrunt-cache`, or `terraform.tfstate*`.

## Docs

- Human-oriented overview: **`README.md`**.
