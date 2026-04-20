# DigitalOcean Kubernetes (DOKS) — Terraform

This repository provisions a **DigitalOcean Kubernetes (DOKS)** cluster and the supporting control-plane pieces on the platform: **DNS**, **TLS (cert-manager + Let’s Encrypt)**, **Traefik** as ingress, and **Argo CD** to sync workloads from Git. Sample app manifests live under `k8s/` and are wired for GitOps-style delivery.

## What gets created (high level)

| Layer | Resources |
|--------|-----------|
| **DigitalOcean** | Project, managed domain, single-node-pool DOKS cluster, DNS A records for `@`, `*`, `argocd`, and `traefik` |
| **Kubernetes** | cert-manager (Helm), ClusterIssuer (DNS-01 via DO API), wildcard TLS `Certificate` for Traefik, Traefik (Helm, LoadBalancer), Argo CD + `argocd-apps` Application pointing at this repo |

**Dependency order in root `main.tf`:** cluster → cert-manager & Traefik → DNS (needs Traefik LB IP) → Argo CD (after cluster, network, Traefik, cert-manager).

## Project structure

```
.
├── main.tf                    # Root stack: DO project/domain, module wiring, providers
├── variables.tf               # Root input variables
├── environments/
│   └── dev.tfvars             # Example non-secret values for dev
├── modules/
│   ├── digitalocean/
│   │   ├── cluster/           # DOKS cluster (node pool, kubeconfig outputs for providers)
│   │   └── network/           # DO DNS A records → Traefik LoadBalancer IP
│   └── kubernetes/
│       ├── cert_manager/      # Helm cert-manager, DO DNS secret, ClusterIssuer + wildcard cert
│       ├── traefik/           # Helm Traefik, IngressRoute for dashboard host
│       └── argocd/            # Helm Argo CD + Application to sync a path in Git
├── k8s/
│   └── apps/
│       └── dev/               # Kustomize + sample app; path referenced by Argo CD
└── .github/workflows/
    └── terraform.yml          # fmt/plan on PR; apply on push to main (expects Terraform Cloud token)
```

### Root (`main.tf`)

- Configures **providers**: `digitalocean`, `kubernetes`, aliased `kubernetes.k8s`, and `helm` using the cluster module’s API endpoint, token, and CA.
- Creates a **DigitalOcean project**, registers a **domain**, and attaches the cluster URN and domain URN to the project.
- Composes the modules below in order so Kubernetes and DNS stay consistent.

### Module: `modules/digitalocean/cluster`

- **`digitalocean_kubernetes_cluster`**: named cluster, region, Kubernetes version, single **node pool** (size + count from variables).
- **Outputs** used by the root providers: `endpoint`, `token`, `cluster_ca_certificate`, `cluster_urn`; sensitive kubeconfig raw YAML is also exposed from the resource.

### Module: `modules/digitalocean/network`

- **Inputs:** root domain name, region (passed through), and **`traefik_lb_ip`** from the Traefik module (the LoadBalancer IP assigned by DO once Traefik’s Service is ready).
- **Resources:** `digitalocean_record` A records for apex `@`, wildcard `*`, `argocd`, and `traefik` subdomains, all pointing at that IP.
- *Note:* the module still declares a `data "kubernetes_service"` for Traefik; the records use the **`traefik_lb_ip` variable** from the parent, not that data source.

### Module: `modules/kubernetes/cert_manager`

- **Helm:** `jetstack/cert-manager` with CRDs, namespace `cert-manager`.
- **Secret:** `do-dns` in `cert-manager` with the DO API token for **DNS-01** challenges.
- **`null_resource`:** waits until cert-manager CRDs exist (uses local `kubectl`).
- **`kubernetes_manifest`:** ClusterIssuer `letsencrypt-prod` (Let’s Encrypt production) and a **wildcard** `Certificate` in namespace `traefik`, storing TLS in the secret name from `var.tls_secret_name` (default `bizquery-wildcard-tls`).

### Module: `modules/kubernetes/traefik`

- **Helm:** Traefik from `helm.traefik.io`, namespace `traefik`, values from `values.yaml.tpl` (LoadBalancer Service, default TLS store pointing at the wildcard secret, dashboard exposed via `IngressRoute` on `traefik.<domain>`).
- Uses the **aliased** `kubernetes.k8s` provider for reading the Service and **outputs** `traefik_lb_ip` from the LoadBalancer status (used by the network module).

### Module: `modules/kubernetes/argocd`

- **Helm:** `argo-cd` with server URL `https://argocd.<domain>`, ClusterIP service, admin password from **bcrypt hash** variable.
- **Helm:** `argocd-apps` chart defining one **Application** that syncs `repo_url` / `branch` / `manifests_path` into `app_namespace` with automated sync and prune.

### `k8s/` — manifests and GitOps

- **`k8s/apps/dev/`** is the path used in `environments/dev.tfvars` (`manifests_path = "k8s/apps/dev"`) for the Terraform-managed Argo CD Application.
- Contains **Kustomize** layout (`kustomization.yaml` includes `loading-page/`) and an optional **`ApplicationSet`** (`argocd-applicationset.yaml`) for additional list-based apps—ensure Argo CD is configured to use whichever pattern you rely on (single Application vs ApplicationSet) to avoid duplicate or conflicting definitions.

## Variables (root)

| Variable | Purpose |
|----------|---------|
| `do_token` | DigitalOcean API token (sensitive); used by provider and cert-manager DNS secret |
| `do_region` | Region slug (e.g. `fra1`) |
| `project_name` | DO project name |
| `name` | DOKS cluster name |
| `node_count` / `node_size` / `k8s_version` | Node pool sizing and DOKS version string |
| `domain_name` | Apex domain for DNS and TLS |
| `email` | ACME registration email |
| `tls_secret_name` | Secret name for wildcard cert (Traefik default cert) |
| `repo_url` / `branch` / `manifests_path` | Git source for Argo CD Application |
| `env` | Environment label (e.g. `dev`) |
| `app_namespace` | Namespace Argo CD deploys into |
| `argocd_admin_password_hash` | Bcrypt hash for Argo CD admin (sensitive) |

Pass **sensitive** values via environment, `-var`, or a `*.tfvars` file that is **not** committed.

## Usage

```bash
cd /path/to/do-terraform

export DIGITALOCEAN_TOKEN="..."   # or rely on var.do_token in tfvars / -var

terraform init
terraform plan  -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

Ensure **`kubectl`** is available on the machine running apply if you rely on the cert-manager module’s `local-exec` waiter.

## CI (`.github/workflows/terraform.yml`)

- Runs **`terraform fmt -check`**, **`plan`**, and on **`main`** push **`apply -auto-approve`**.
- Expects **`TF_API_TOKEN`** (Terraform Cloud) for `hashicorp/setup-terraform`; align this with your backend (the sample workflow assumes remote/TFC-style credentials). If you use **local state**, adjust the workflow and secrets accordingly.

## Providers (versions)

Root `terraform` block pins **DigitalOcean**, **Kubernetes**, **Helm**, and **template** providers; submodule `versions.tf` files repeat constraints where modules declare their own `terraform` blocks.
