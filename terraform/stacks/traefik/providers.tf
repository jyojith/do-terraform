locals {
  # DigitalOcean kube_config.cluster_ca_certificate is normally base64(PEM). Pass via variables (not Terragrunt-generated
  # quoted strings) so multi-line PEM or large values are not mangled. If already PEM, use as-is.
  _k8s_ca_trim       = trimspace(var.k8s_cluster_ca_certificate)
  k8s_cluster_ca_pem = startswith(local._k8s_ca_trim, "-----BEGIN") ? local._k8s_ca_trim : base64decode(local._k8s_ca_trim)
}

provider "kubernetes" {
  host                   = var.k8s_host
  token                  = var.k8s_token
  cluster_ca_certificate = local.k8s_cluster_ca_pem
}

provider "kubernetes" {
  alias                  = "k8s"
  host                   = var.k8s_host
  token                  = var.k8s_token
  cluster_ca_certificate = local.k8s_cluster_ca_pem
}

provider "helm" {
  kubernetes = {
    host                   = var.k8s_host
    token                  = var.k8s_token
    cluster_ca_certificate = local.k8s_cluster_ca_pem
  }
}
