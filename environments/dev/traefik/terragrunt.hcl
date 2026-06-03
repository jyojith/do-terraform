include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  # File-based mock: long sensitive YAML via TF_VAR_* env can be truncated; file() passes full content to OpenTofu.
  mock_kubeconfig_file = "${get_terragrunt_dir()}/../mock-kubeconfig.yaml"
  k8s_kubeconfig_yaml  = get_env("TF_VAR_k8s_kubeconfig_yaml", "")
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
  dashboard_password_hash = var.traefik_dashboard_password_hash
  providers = {
    kubernetes     = kubernetes
    kubernetes.k8s = kubernetes.k8s
  }
}
EOF
}

dependency "doks" {
  enabled     = length(trimspace(local.k8s_kubeconfig_yaml)) == 0
  config_path = "../doks"
  mock_outputs = {
    kubeconfig = file(local.mock_kubeconfig_file)
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
  domain_name                     = local.env.locals.domain_name
  email                           = local.env.locals.email
  do_token                        = length(trimspace(get_env("TF_VAR_do_token", ""))) > 0 ? get_env("TF_VAR_do_token", "") : get_env("DO_TOKEN", "")
  traefik_dashboard_password_hash = get_env("TF_VAR_traefik_dashboard_password_hash", "")
  # coalesce/whitespace: dependency can yield "" or whitespace-only; that is not valid YAML/PEM.
  k8s_kubeconfig_yaml = length(trimspace(local.k8s_kubeconfig_yaml)) > 0 ? local.k8s_kubeconfig_yaml : (length(trimspace(try(dependency.doks.outputs.kubeconfig, ""))) > 0 ? dependency.doks.outputs.kubeconfig : file(local.mock_kubeconfig_file))
}
