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

dependency "traefik" {
  config_path = "../traefik"
  mock_outputs = {
    traefik_lb_ip = "203.0.113.50"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/terraform/stacks/dns"
}

inputs = {
  domain_name   = local.env.locals.domain_name
  region        = local.env.locals.do_region
  traefik_lb_ip = dependency.traefik.outputs.traefik_lb_ip
  do_token      = length(trimspace(get_env("TF_VAR_do_token", ""))) > 0 ? get_env("TF_VAR_do_token", "") : get_env("DO_TOKEN", "")
}
