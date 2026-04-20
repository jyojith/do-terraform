variable "domain_name" {
  description = "Domain name for routing"
  type        = string
}

variable "tls_secret_name" {
  description = "Kubernetes TLS secret name for Traefik default cert"
  type        = string
  default     = "bizquery-wildcard-tls"
}
