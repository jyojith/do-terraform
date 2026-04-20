variable "domain_name" {
  description = "Apex domain for ACME and routes"
  type        = string
}

variable "email" {
  description = "Email for Let's Encrypt (Traefik ACME)"
  type        = string
}

variable "do_token" {
  description = "DigitalOcean API token for DNS-01 challenge"
  type        = string
  sensitive   = true
}

variable "k8s_host" {
  description = "Kubernetes API server URL (from DOKS cluster endpoint)"
  type        = string
}

variable "k8s_token" {
  description = "Kubernetes bearer token for the cluster"
  type        = string
  sensitive   = true
}

variable "k8s_cluster_ca_certificate" {
  description = "Cluster CA cert from DOKS kube_config (base64-encoded PEM, or PEM text)"
  type        = string
  sensitive   = true
}
