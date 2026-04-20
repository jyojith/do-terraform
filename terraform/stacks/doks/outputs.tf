output "endpoint" {
  value = module.cluster.endpoint
}

output "token" {
  value     = module.cluster.token
  sensitive = true
}

output "cluster_ca_certificate" {
  value = module.cluster.cluster_ca_certificate
}

output "cluster_urn" {
  value = module.cluster.cluster_urn
}

output "domain_urn" {
  value = digitalocean_domain.this.urn
}
