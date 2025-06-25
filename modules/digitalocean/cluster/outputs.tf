output "endpoint" {
  value = digitalocean_kubernetes_cluster.main.endpoint
}

output "token" {
  value = digitalocean_kubernetes_cluster.main.kube_config[0].token
}

output "cluster_ca_certificate" {
  value = digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
}

output "cluster_urn" {
  value = digitalocean_kubernetes_cluster.main.urn
}
