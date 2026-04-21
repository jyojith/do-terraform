data "digitalocean_kubernetes_versions" "available" {}

locals {
  # Allow explicit version pinning, but default to the latest supported version to avoid stale slugs.
  effective_k8s_version = length(trimspace(var.k8s_version)) > 0 ? var.k8s_version : data.digitalocean_kubernetes_versions.available.latest_version
}

resource "digitalocean_kubernetes_cluster" "main" {
  name    = var.name
  region  = var.do_region
  version = local.effective_k8s_version

  node_pool {
    name       = "${var.name}-pool"
    size       = var.node_size
    node_count = var.node_count
  }
}

output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
  sensitive = true
}
