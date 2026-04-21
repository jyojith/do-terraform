# Shared Terragrunt configuration for all stacks under environments/.
# Each stack includes this file via: include "root" { path = find_in_parent_folders("root.hcl") }
#
# Remote state: S3-compatible (e.g. DigitalOcean Spaces) when AWS_* + TG_STATE_* are set.
# Otherwise "local" backend for fmt/validate CI without Spaces.
#
# For DigitalOcean Spaces, set TG_STATE_ENDPOINT to the *regional* S3 API host
# (e.g. https://fra1.digitaloceanspaces.com), not the bucket vhost. Bucket = TG_STATE_BUCKET.
# Backend "region" is an AWS *signing* name (e.g. us-east-1); use TG_S3_REGION to override.
# See: https://docs.digitalocean.com/reference/terraform/backend/
#
# The S3 backend must skip STS credential validation: DO keys are not valid for AWS
# (otherwise: InvalidClientTokenId). That requires real booleans in generated backend.tf;
# remote_state { config = { ... } } stringifies "true" and breaks decode, so we use
# a generate block instead of remote_state.

terraform_version_constraint = ">= 1.5.0"

locals {
  state_bucket   = get_env("TG_STATE_BUCKET", "")
  state_endpoint = get_env("TG_STATE_ENDPOINT", "")
  # AWS SigV4 signing region for the S3 backend (must be a real AWS name, e.g. us-east-1 for Spaces).
  s3_signing_region = get_env("TG_S3_REGION", "us-east-1")
  has_aws           = length(trimspace(get_env("AWS_ACCESS_KEY_ID", ""))) > 0 && length(trimspace(get_env("AWS_SECRET_ACCESS_KEY", ""))) > 0
  has_s3_target     = length(trimspace(local.state_bucket)) > 0 && length(trimspace(local.state_endpoint)) > 0
  use_s3            = local.has_aws && local.has_s3_target

  # backend.tf: bools must live in HCL (not in remote_state config map) for S3/Spaces.
  backend_tf = local.use_s3 ? (<<-EOT
terraform {
  backend "s3" {
    bucket  = "${local.state_bucket}"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "${local.s3_signing_region}"
    endpoint = "${local.state_endpoint}"

    skip_credentials_validation    = true
    skip_metadata_api_check         = true
    skip_requesting_account_id     = true
  }
}
EOT
  ) : (<<-EOT
terraform {
  backend "local" {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}
EOT
  )
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.backend_tf
}
