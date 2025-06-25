resource "digitalocean_kubernetes_cluster" "main" {
  name    = var.name
  region  = var.do_region
  version = var.k8s_version

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
