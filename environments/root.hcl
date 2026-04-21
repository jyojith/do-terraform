# Shared Terragrunt configuration for all stacks under environments/.
# Each stack includes this file via: include "root" { path = find_in_parent_folders("root.hcl") }

terraform_version_constraint = ">= 1.5.0"

locals {
  state_bucket   = get_env("TG_STATE_BUCKET", "bizquery-tf")
  state_region   = get_env("TG_STATE_REGION", "us-east-1")
  state_endpoint = get_env("TG_STATE_ENDPOINT", "https://fra1.digitaloceanspaces.com")
}

remote_state {
  backend = "s3"
  config = {
    bucket   = local.state_bucket
    key      = "${path_relative_to_include()}/terraform.tfstate"
    region   = local.state_region
    endpoint = local.state_endpoint

    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true

    # DigitalOcean Spaces is S3-compatible but doesn't expose all AWS bucket controls
    # Terragrunt tries to verify/manage (SSE/versioning/etc) by default and can fail with 403.
    skip_bucket_versioning  = true
    skip_bucket_ssencryption = true
    skip_bucket_accesslogging = true
    skip_bucket_root_access = true
    skip_bucket_enforced_tls = true
    skip_bucket_public_access_blocking = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
