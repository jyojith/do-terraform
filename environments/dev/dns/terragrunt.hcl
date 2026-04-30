include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

generate "network_module" {
  path      = "network.module.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
module "network" {
  source        = "${get_repo_root()}/modules/digitalocean/network"
  domain_name   = var.domain_name
  region        = var.region
  traefik_lb_ip = var.traefik_lb_ip
}
EOF
}

dependency "traefik" {
  config_path = "../traefik"
  mock_outputs = {
    traefik_lb_ip = "203.0.113.50"
  }
  # init / destroy / state: when traefik_lb_ip is missing from remote state, Terragrunt must still
  # resolve this block or inputs fail with "Unknown variable". Do not add "apply" (real LB IP required).
  mock_outputs_allowed_terraform_commands = [
    "init", "validate", "plan", "import", "destroy", "state"
  ]
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
