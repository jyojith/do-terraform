# Non-secret defaults for the dev account. Override or extend via stack terragrunt.hcl / env vars.
# Sensitive values (do_token, argocd_admin_password_hash) are supplied via TF_VAR_* or stack inputs.

locals {
  env             = "dev"
  do_region       = "fra1"
  project_name    = "bizquery-dev"
  name            = "bizquery-k8s-dev"
  node_count      = 1
  node_size       = "s-1vcpu-2gb"
  k8s_version     = "1.33.1-do.1"
  domain_name     = "bizquery.dev"
  email           = "admin@unisphere.wiki"
  repo_url        = "https://github.com/jyojith/do-terraform"
  branch          = "main"
  manifests_path  = "k8s/apps/dev"
  app_namespace   = "bizquery-dev"
  tls_secret_name = "bizquery-wildcard-tls"
}
