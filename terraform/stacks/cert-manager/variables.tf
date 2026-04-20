variable "do_token" {
  description = "DigitalOcean API token (cert-manager DNS-01)"
  type        = string
  sensitive   = true
}

variable "email" {
  description = "Email address for certificate issuance"
  type        = string
}

variable "domain_name" {
  description = "Domain name for TLS"
  type        = string
}

variable "tls_secret_name" {
  description = "Kubernetes TLS secret name for wildcard cert"
  type        = string
  default     = "bizquery-wildcard-tls"
}
