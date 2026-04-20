locals {
  _k8s_ca_trim       = trimspace(var.k8s_cluster_ca_certificate)
  k8s_cluster_ca_pem = startswith(local._k8s_ca_trim, "-----BEGIN") ? local._k8s_ca_trim : base64decode(local._k8s_ca_trim)
}

provider "helm" {
  kubernetes = {
    host                   = var.k8s_host
    token                  = var.k8s_token
    cluster_ca_certificate = local.k8s_cluster_ca_pem
  }
}
