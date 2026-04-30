locals {
  # Use the same kubeconfig YAML DigitalOcean emits (raw_config) as kubectl — avoids PEM/DER/base64 mismatches from
  # reassembling host/token/CA from separate outputs.
  _kc                = yamldecode(trimspace(var.k8s_kubeconfig_yaml))
  _cur               = local._kc["current-context"]
  _ctx               = one([for x in local._kc.contexts : x.context if x.name == local._cur])
  _cname             = local._ctx.cluster
  _uname             = local._ctx.user
  _cluster_block     = one([for c in local._kc.clusters : c.cluster if c.name == local._cname])
  _user_block        = one([for u in local._kc.users : u.user if u.name == local._uname])
  k8s_host           = local._cluster_block.server
  k8s_token          = try(local._user_block.token, "")
  _ca_b64            = local._cluster_block["certificate-authority-data"]
  k8s_cluster_ca_pem = base64decode(replace(replace(local._ca_b64, "\n", ""), " ", ""))
}

provider "kubernetes" {
  host                   = local.k8s_host
  token                  = local.k8s_token
  cluster_ca_certificate = local.k8s_cluster_ca_pem
}

provider "kubernetes" {
  alias                  = "k8s"
  host                   = local.k8s_host
  token                  = local.k8s_token
  cluster_ca_certificate = local.k8s_cluster_ca_pem
}

provider "time" {}

provider "helm" {
  # Isolate Helm repo config/cache from the machine default (~/.config/helm, ~/Library/Caches/helm).
  # A stale or missing Bitnami index in the global cache breaks `helm_release` even for unrelated charts.
  repository_config_path = "${path.module}/helm/repositories.yaml"
  repository_cache       = "${path.module}/helm/repository-cache"

  kubernetes = {
    host                   = local.k8s_host
    token                  = local.k8s_token
    cluster_ca_certificate = local.k8s_cluster_ca_pem
  }
}
