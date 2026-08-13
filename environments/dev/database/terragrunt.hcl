include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# Terraform 1.4+ forbids locals in module source; Terragrunt expands get_repo_root() to a literal path.
generate "database_module" {
  path      = "database.module.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
module "database" {
  source          = "${get_repo_root()}/modules/digitalocean/database"
  do_region       = var.do_region
  name            = var.name
  size            = var.size
  node_count      = var.node_count
  pg_version      = var.pg_version
  vpc_uuid        = var.vpc_uuid
  doks_cluster_id = var.doks_cluster_id
  db_name         = var.db_name
  db_user         = var.db_user
}
EOF
}

dependency "doks" {
  config_path = "../doks"
  mock_outputs = {
    vpc_uuid   = "00000000-0000-0000-0000-000000000000"
    cluster_id = "00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/terraform/stacks/database"
}

inputs = {
  do_token        = length(trimspace(get_env("TF_VAR_do_token", ""))) > 0 ? get_env("TF_VAR_do_token", "") : get_env("DO_TOKEN", "")
  do_region       = local.env.locals.do_region
  project_name    = local.env.locals.project_name
  name            = "${local.env.locals.name}-postgres"
  vpc_uuid        = dependency.doks.outputs.vpc_uuid
  doks_cluster_id = dependency.doks.outputs.cluster_id
}
