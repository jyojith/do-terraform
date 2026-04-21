# Shared Terragrunt configuration for all stacks under environments/.
# Each stack includes this file via: include "root" { path = find_in_parent_folders("root.hcl") }

terraform_version_constraint = ">= 1.5.0"

locals {
  state_bucket   = get_env("TG_STATE_BUCKET", "")
  state_region   = get_env("TG_STATE_REGION", "us-east-1")
  state_endpoint = get_env("TG_STATE_ENDPOINT", "")
  use_s3_backend = length(trimspace(local.state_bucket)) > 0 && length(trimspace(local.state_endpoint)) > 0
}

remote_state {
  backend = local.use_s3_backend ? "s3" : "local"
  config = local.use_s3_backend ? {
    bucket = local.state_bucket
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = local.state_region

    endpoint = local.state_endpoint

    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  } : {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
