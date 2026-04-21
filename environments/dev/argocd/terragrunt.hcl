include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env                  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  mock_kubeconfig_file = "${get_terragrunt_dir()}/../mock-kubeconfig.yaml"
}

generate "argocd_module" {
  path      = "argocd.module.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
module "argocd" {
  source                     = "${get_repo_root()}/modules/kubernetes/argocd"
  domain_name                = var.domain_name
  repo_url                   = var.repo_url
  branch                     = var.branch
  manifests_path             = var.manifests_path
  env                        = var.env
  app_namespace              = var.app_namespace
  argocd_namespace           = "argocd"
  argocd_admin_password_hash = var.argocd_admin_password_hash
}
EOF
}

dependency "doks" {
  config_path = "../doks"
  mock_outputs = {
    kubeconfig = file(local.mock_kubeconfig_file)
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

generate "providers_legacy_stub" {
  path      = "providers.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = "# Superseded by providers.tf in the stack (inputs from Terragrunt).\n"
}

inputs = {
  domain_name                = local.env.locals.domain_name
  repo_url                   = local.env.locals.repo_url
  branch                     = local.env.locals.branch
  manifests_path             = local.env.locals.manifests_path
  env                        = local.env.locals.env
  app_namespace              = local.env.locals.app_namespace
  argocd_admin_password_hash = get_env("TF_VAR_argocd_admin_password_hash", "")
  k8s_kubeconfig_yaml        = length(trimspace(try(dependency.doks.outputs.kubeconfig, ""))) > 0 ? dependency.doks.outputs.kubeconfig : file(local.mock_kubeconfig_file)
}
