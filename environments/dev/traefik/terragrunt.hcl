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

dependency "doks" {
  config_path = "../doks"
  mock_outputs = {
    endpoint               = "https://127.0.0.1:6443"
    token                  = "mock"
    cluster_ca_certificate = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJMU1Ea3hNVEU1TlRJeE1Wb1hEVEkxTURreE1URTVOVEl4TVZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTUxjCnR6dHh0bVd3YkZ3U1VwTlVvZ1VnPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/terraform/stacks/traefik"
}

generate "providers" {
  path      = "providers.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "kubernetes" {
  host                   = "${dependency.doks.outputs.endpoint}"
  token                  = "${dependency.doks.outputs.token}"
  cluster_ca_certificate = base64decode("${dependency.doks.outputs.cluster_ca_certificate}")
}

provider "kubernetes" {
  alias                  = "k8s"
  host                   = "${dependency.doks.outputs.endpoint}"
  token                  = "${dependency.doks.outputs.token}"
  cluster_ca_certificate = base64decode("${dependency.doks.outputs.cluster_ca_certificate}")
}

provider "helm" {
  kubernetes = {
    host                   = "${dependency.doks.outputs.endpoint}"
    token                  = "${dependency.doks.outputs.token}"
    cluster_ca_certificate = base64decode("${dependency.doks.outputs.cluster_ca_certificate}")
  }
}
EOF
}

inputs = {
  domain_name = local.env.locals.domain_name
  email       = local.env.locals.email
  do_token    = length(trimspace(get_env("TF_VAR_do_token", ""))) > 0 ? get_env("TF_VAR_do_token", "") : get_env("DO_TOKEN", "")
}
