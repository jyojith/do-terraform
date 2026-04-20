include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

generate "repo_paths" {
  path      = "repo_paths.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
locals {
  repo_root = "${get_repo_root()}"
}
EOF
}

dependency "doks" {
  config_path = "../doks"
  mock_outputs = {
    endpoint               = "https://127.0.0.1:6443"
    token                  = "mock"
    cluster_ca_certificate = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJMU1Ea3hNVEU1TlRJeE1Wb1hEVEkxTURreE1URTVOVEl4TVZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTUxjCnR6dHh0bVd3YkZ3U1VwTlVvZ1VnPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Ordering: Argo CD after Traefik (ACME) and DNS exist.
dependencies {
  paths = [
    "../traefik",
    "../dns",
  ]
}

terraform {
  source = "${get_repo_root()}/terraform/stacks/argocd"
}

generate "providers" {
  path      = "providers.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "helm" {
  kubernetes = {
    host                   = "${dependency.doks.outputs.endpoint}"
    token                  = "${dependency.doks.outputs.token}"
    cluster_ca_certificate = base64decode("${dependency.doks.outputs.cluster_ca_certificate}")
  }
}
EOF
}

inputs = {
  domain_name                = local.env.locals.domain_name
  repo_url                   = local.env.locals.repo_url
  branch                     = local.env.locals.branch
  manifests_path             = local.env.locals.manifests_path
  env                        = local.env.locals.env
  app_namespace              = local.env.locals.app_namespace
  argocd_admin_password_hash = get_env("TF_VAR_argocd_admin_password_hash", "")
}
