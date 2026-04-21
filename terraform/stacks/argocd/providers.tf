locals {
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

provider "helm" {
  repository_config_path = "${path.module}/helm/repositories.yaml"
  repository_cache       = "${path.module}/helm/repository-cache"

  kubernetes = {
    host                   = local.k8s_host
    token                  = local.k8s_token
    cluster_ca_certificate = local.k8s_cluster_ca_pem
  }
}
