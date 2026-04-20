include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

generate "traefik_module" {
  path      = "traefik.module.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
module "traefik" {
  source      = "${get_repo_root()}/modules/kubernetes/traefik"
  domain_name = var.domain_name
  email       = var.email
  do_token    = var.do_token
  providers = {
    kubernetes     = kubernetes
    kubernetes.k8s = kubernetes.k8s
  }
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

terraform {
  source = "${get_repo_root()}/terraform/stacks/traefik"
}

# Overwrite any cached providers.generated.tf from older Terragrunt; provider config lives in terraform/stacks/traefik/providers.tf.
generate "providers_legacy_stub" {
  path      = "providers.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = "# Superseded by providers.tf in the stack (inputs from Terragrunt).\n"
}

inputs = {
  domain_name = local.env.locals.domain_name
  email       = local.env.locals.email
  do_token    = length(trimspace(get_env("TF_VAR_do_token", ""))) > 0 ? get_env("TF_VAR_do_token", "") : get_env("DO_TOKEN", "")
  k8s_host                   = dependency.doks.outputs.endpoint
  k8s_token                  = dependency.doks.outputs.token
  k8s_cluster_ca_certificate = dependency.doks.outputs.cluster_ca_certificate
}
