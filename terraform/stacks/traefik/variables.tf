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

variable "k8s_kubeconfig_yaml" {
  description = "Full kubeconfig YAML from DOKS (module output kubeconfig / raw_config)"
  type        = string
  sensitive   = true
}
