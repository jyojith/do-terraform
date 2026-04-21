output "endpoint" {
  value = module.cluster.endpoint
}

output "token" {
  value     = module.cluster.token
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.cluster.cluster_ca_certificate
  sensitive = true
}

output "kubeconfig" {
  description = "Full kubeconfig YAML (raw_config); preferred for downstream kubernetes/helm providers"
  value       = module.cluster.kubeconfig
  sensitive   = true
}

output "cluster_urn" {
  value = module.cluster.cluster_urn
}

output "domain_urn" {
  value = data.digitalocean_domain.existing.urn
}
