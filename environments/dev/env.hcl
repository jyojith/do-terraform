# Non-secret defaults for the dev account. Override or extend via stack terragrunt.hcl / env vars.
# Sensitive values (do_token, argocd_admin_password_hash) are supplied via TF_VAR_* or stack inputs.

locals {
  env          = "dev"
  do_region    = "fra1"
  project_name = "bizquery-dev"
  name         = "bizquery-k8s-dev"
  node_count   = 1
  node_size    = "s-2vcpu-4gb" # bumped from s-1vcpu-2gb: 1 node shares ArgoCD+Traefik+system + api/worker/postgres
  # Leave empty to use the latest available DigitalOcean Kubernetes version.
  k8s_version = ""
  domain_name = "bizquery.dev"
  email       = "admin@unisphere.wiki"
  dns_records = {
    "@" = {
      ttl = 60
    }
    argocd = {
      ttl = 300
    }
    traefik = {
      ttl = 60
    }
    app = {
      ttl = 300
    }
  }
  repo_url       = "https://github.com/jyojith/do-terraform"
  branch         = "main"
  manifests_path = "k8s/apps/dev"
  app_namespace  = "bizquery-dev"
}
