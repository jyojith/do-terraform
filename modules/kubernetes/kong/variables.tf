variable "domain_name" {
  description = "Domain name for routing"
  type        = string
}

variable "wildcard_secret_name" {
  type        = string
  default     = "bizquery-wildcard-tls"
  description = "Name of wildcard TLS secret to sync"
}
