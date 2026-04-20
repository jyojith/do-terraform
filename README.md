# DigitalOcean Kubernetes (DOKS) — Terragrunt + Terraform

This repository provisions a **DigitalOcean Kubernetes (DOKS)** cluster and supporting pieces: **project + domain**, **cert-manager** (Let’s Encrypt DNS-01), **Traefik** ingress, **DNS A records**, and **Argo CD** GitOps. Infrastructure is split into **Terragrunt stacks** under `live/dev/` with separate state per stack, explicit **dependencies**, and **DRY** shared config.

## Why Terragrunt?

- **Separate state** per layer (cluster vs addons vs DNS) for safer blast radius and parallel plans where possible.
- **`dependency` blocks** wire Kubernetes/Helm providers from the `doks` stack outputs (endpoint, token, CA).
- **`live/dev/env.hcl`** holds non-secret defaults; tokens and Argo CD password hash come from **`TF_VAR_*`** / **`DO_TOKEN`**.

## Stack layout and dependency graph

Execution order for `terragrunt run-all apply` (from `live/dev/`):

| Order | Stack          | Purpose |
|-------|----------------|---------|
| 1     | `doks`         | DO project, domain, DOKS cluster, project↔resource attachment |
| 2     | `cert-manager` | cert-manager Helm, DO DNS secret, ClusterIssuer, wildcard cert |
| 2     | `traefik`      | Traefik Helm (LoadBalancer), dashboard `IngressRoute` |
| 3     | `dns`          | DO DNS A records → Traefik LB IP |
| 4     | `argocd`       | Argo CD + `argocd-apps` Application |

`cert-manager` and `traefik` both depend only on `doks` and can run in parallel. `dns` depends on `traefik` (needs LB IP). `argocd` depends on `doks` (Helm kube config) and is ordered after `cert-manager`, `traefik`, and `dns`.

## Repository layout

```
.
├── live/
│   ├── root.hcl                 # Shared remote_state (local backend path per stack)
│   └── dev/
│       ├── env.hcl              # Non-secret locals (region, cluster size, domain, Git URLs, …)
│       ├── doks/terragrunt.hcl  # Only Terragrunt: inputs + terraform { source = … }
│       ├── cert-manager/
│       ├── traefik/
│       ├── dns/
│       └── argocd/
├── terraform/stacks/            # Terraform root modules (one directory per stack)
│   ├── doks/
│   ├── cert-manager/
│   ├── traefik/
│   ├── dns/
│   └── argocd/
├── modules/                     # Shared modules called from terraform/stacks/*
│   ├── digitalocean/cluster
│   ├── digitalocean/network
│   └── kubernetes/{cert_manager,traefik,argocd}
├── k8s/apps/dev/                # Sample manifests; path used by Argo CD
└── .github/workflows/terraform.yml   # terragrunt run-all validate/plan/apply
```

**Why split `live/` vs `terraform/stacks/`?**  
`live/` holds **environment-specific** Terragrunt only (dependencies, inputs, generated providers). **`terraform/stacks/`** holds the Terraform root modules once, referenced via `terraform { source = "${get_repo_root()}/terraform/stacks/<stack>" }`. That matches the usual pattern: **thin live config**, **one copy of each stack’s `.tf` files**, shared **`modules/`**.

### Implementation notes

- Each `live/dev/<stack>/terragrunt.hcl` **generates** a tiny `repo_paths.tf` (`local.repo_root = get_repo_root()`) so `${local.repo_root}/modules/...` resolves correctly after Terragrunt copies the stack into `.terragrunt-cache/`. Run stacks with **Terragrunt**, not raw `terraform` in `terraform/stacks/` alone, unless you add that file yourself for local experiments.
- Kubernetes-dependent stacks **generate** `providers.generated.tf` from **`dependency.doks.outputs`** (Helm uses the `kubernetes = { … }` map form required by **Helm provider v3**).
- **Mock outputs** on the `doks` / `traefik` dependencies allow `validate` / `plan` when upstream state is empty (CI / cold start). Real applies use outputs from state after each dependency is applied.

### Remote state

`live/root.hcl` uses a **local** backend with state stored next to each stack (`terraform.tfstate` in that stack directory). For teams, replace this block with **S3**, **GCS**, **Terraform Cloud**, etc., still via Terragrunt’s `remote_state` (see [Terragrunt remote state](https://terragrunt.gruntwork.io/docs/features/keep-your-remote-state-configuration-dry/)).

## Prerequisites

- [Terraform](https://www.terraform.io/) **>= 1.5** (or compatible OpenTofu)
- [Terragrunt](https://terragrunt.gruntwork.io/) (see `TG_VERSION` in `.github/workflows/terraform.yml` for the CI pin)
- `kubectl` on the machine that runs apply (cert-manager module waits for CRDs via `kubectl`)
- DigitalOcean API token with permissions for Kubernetes, DNS, and project resources

## Configure secrets

Export (or use a private `*.auto.tfvars` / CI secrets):

| Variable | Purpose |
|----------|---------|
| `TF_VAR_do_token` or `DO_TOKEN` | DigitalOcean API token |
| `TF_VAR_argocd_admin_password_hash` | Bcrypt hash for Argo CD `admin` |

## Usage

From the repo root:

```bash
cd live/dev

export TF_VAR_do_token="dop_v1_..."   # or export DO_TOKEN="..."
export TF_VAR_argocd_admin_password_hash='$2a$10$...'

terragrunt run-all plan
terragrunt run-all apply
```

Single stack:

```bash
cd live/dev/doks
terragrunt plan
terragrunt apply
```

Formatting:

```bash
terraform fmt -recursive ../../modules ../../terraform/stacks
terragrunt hclfmt --working-dir=.
```

## CI

GitHub Actions (`.github/workflows/terraform.yml`) runs `terraform fmt`, `terragrunt hclfmt`, `terragrunt run-all validate`, `run-all plan`, and on **`main`** push `run-all apply`. Configure repository secrets **`DO_TOKEN`** and **`ARGOCD_ADMIN_PASSWORD_HASH`**. Remove or narrow the **`apply`** step if you do not want automatic applies from GitHub.

## Providers

Stacks pin **DigitalOcean**, **Kubernetes**, **Helm**, and **template** (Traefik values) where needed; versions are resolved per stack’s `versions.tf` and lock files created after `terragrunt init`.
