include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# Terraform 1.4+ forbids locals in module source; Terragrunt expands get_repo_root() to a literal path.
# Use bare var.x (not ${var.x}) so Terragrunt does not treat them as interpolations.
generate "cluster_module" {
  path      = "cluster.module.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
module "cluster" {
  source      = "${get_repo_root()}/modules/digitalocean/cluster"
  do_token    = var.do_token
  do_region   = var.do_region
  name        = var.name
  node_count  = var.node_count
  node_size   = var.node_size
  k8s_version = var.k8s_version
}
EOF
}

terraform {
  source = "${get_repo_root()}/terraform/stacks/doks"
}

inputs = {
  env          = local.env.locals.env
  do_region    = local.env.locals.do_region
  project_name = local.env.locals.project_name
  name         = local.env.locals.name
  node_count   = local.env.locals.node_count
  node_size    = local.env.locals.node_size
  k8s_version  = local.env.locals.k8s_version
  domain_name  = local.env.locals.domain_name
  do_token     = length(trimspace(get_env("TF_VAR_do_token", ""))) > 0 ? get_env("TF_VAR_do_token", "") : get_env("DO_TOKEN", "")
}
