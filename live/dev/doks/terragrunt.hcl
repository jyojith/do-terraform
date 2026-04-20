include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# Terragrunt copies the stack into .terragrunt-cache; relative module paths break.
# This small generated file supplies repo root for ${local.repo_root} in terraform/stacks.
generate "repo_paths" {
  path      = "repo_paths.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
locals {
  repo_root = "${get_repo_root()}"
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
