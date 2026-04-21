# Shared Terragrunt configuration for all stacks under environments/.
# Each stack includes this file via: include "root" { path = find_in_parent_folders("root.hcl") }
#
# Remote state: S3-compatible (e.g. DigitalOcean Spaces) when AWS_* + TG_STATE_* are set.
# Otherwise "local" backend for fmt/validate CI without Spaces.
#
# S3 `config` must be built with merge() and inline bool literals. Terragrunt 0.67 coerces
# booleans to strings when a map is selected via ternary (e.g. `? local.remote_s3`).

terraform_version_constraint = ">= 1.5.0"

locals {
  state_bucket   = get_env("TG_STATE_BUCKET", "")
  state_region   = get_env("TG_STATE_REGION", "fra1")
  state_endpoint = get_env("TG_STATE_ENDPOINT", "")
  has_aws        = length(trimspace(get_env("AWS_ACCESS_KEY_ID", ""))) > 0 && length(trimspace(get_env("AWS_SECRET_ACCESS_KEY", ""))) > 0
  has_s3_target  = length(trimspace(local.state_bucket)) > 0 && length(trimspace(local.state_endpoint)) > 0
  use_s3         = local.has_aws && local.has_s3_target
}

remote_state {
  backend = local.use_s3 ? "s3" : "local"
  config = local.use_s3 ? merge(
    {
      bucket   = local.state_bucket
      key      = "${path_relative_to_include()}/terraform.tfstate"
      region   = local.state_region
      endpoint = local.state_endpoint
    },
    {
      skip_credentials_validation = true
      skip_requesting_account_id  = true
      skip_metadata_api_check     = true
      skip_region_validation      = true
    },
    {
      skip_bucket_versioning             = true
      skip_bucket_ssencryption           = true
      skip_bucket_accesslogging          = true
      skip_bucket_root_access            = true
      skip_bucket_enforced_tls          = true
      skip_bucket_public_access_blocking = true
    }
  ) : {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
