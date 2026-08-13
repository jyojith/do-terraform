include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env                  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  mock_kubeconfig_file = "${get_terragrunt_dir()}/../mock-kubeconfig.yaml"
  k8s_kubeconfig_yaml  = get_env("TF_VAR_k8s_kubeconfig_yaml", "")
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
  deploy_repo_url            = var.deploy_repo_url
  website_deploy_repo_url    = var.website_deploy_repo_url
  deploy_repo_pat            = var.deploy_repo_pat
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

dependency "database" {
  config_path = "../database"
  mock_outputs = {
    database_url = "postgresql+psycopg://mock:mock@mock:5432/mock?sslmode=require"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Ordering: Argo CD after Traefik (ACME), DNS, and the database exist.
dependencies {
  paths = [
    "../traefik",
    "../dns",
    "../database",
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
  do_model_access_key        = get_env("TF_VAR_do_model_access_key", "")
  db_url                     = dependency.database.outputs.database_url
  ghcr_username              = get_env("TF_VAR_ghcr_username", "")
  ghcr_pat                   = get_env("TF_VAR_ghcr_pat", "")
  deploy_repo_url            = local.env.locals.deploy_repo_url
  website_deploy_repo_url    = local.env.locals.website_deploy_repo_url
  deploy_repo_pat            = get_env("TF_VAR_deploy_repo_pat", "")
  k8s_kubeconfig_yaml        = length(trimspace(local.k8s_kubeconfig_yaml)) > 0 ? local.k8s_kubeconfig_yaml : (length(trimspace(try(dependency.doks.outputs.kubeconfig, ""))) > 0 ? dependency.doks.outputs.kubeconfig : file(local.mock_kubeconfig_file))
}
