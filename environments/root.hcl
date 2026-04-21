# Shared Terragrunt configuration for all stacks under environments/.
# Each stack includes this file via: include "root" { path = find_in_parent_folders("root.hcl") }
#
# Remote state: S3-compatible (e.g. DigitalOcean Spaces) when AWS_* + TG_STATE_* are set.
# Otherwise "local" backend for fmt/validate CI without Spaces.
#
# For DigitalOcean Spaces, TG_STATE_REGION is the *Spaces datacenter* (e.g. fra1) in the endpoint
# URL. The S3 backend "region" must be a *valid AWS region name* (e.g. us-east-1) for SigV4/STS;
# otherwise the SDK looks up sts.<region>.amazonaws.com and fails (e.g. sts.fra1.amazonaws.com).
# See: https://docs.digitalocean.com/reference/terraform/backend/
#
# Terragrunt: avoid boolean flags in remote_state config (decode coerces to string "true").
# Use string fields; optional TG_S3_REGION overrides the signing region.

terraform_version_constraint = ">= 1.5.0"

locals {
  state_bucket   = get_env("TG_STATE_BUCKET", "")
  state_endpoint = get_env("TG_STATE_ENDPOINT", "")
  # AWS SigV4 signing region for the S3 backend (must be a real AWS region, not a DO slug like fra1).
  s3_signing_region = get_env("TG_S3_REGION", "us-east-1")
  has_aws           = length(trimspace(get_env("AWS_ACCESS_KEY_ID", ""))) > 0 && length(trimspace(get_env("AWS_SECRET_ACCESS_KEY", ""))) > 0
  has_s3_target     = length(trimspace(local.state_bucket)) > 0 && length(trimspace(local.state_endpoint)) > 0
  use_s3            = local.has_aws && local.has_s3_target
}

remote_state {
  backend = local.use_s3 ? "s3" : "local"
  # String fields only — no booleans (avoids Terragrunt decoding "true" as string and failing).
  config = local.use_s3 ? {
    bucket   = local.state_bucket
    key      = "${path_relative_to_include()}/terraform.tfstate"
    region   = local.s3_signing_region
    endpoint = local.state_endpoint
  } : {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
