variable "domain_name" {
  description = "Apex domain (ACME DNS-01 and routes)"
  type        = string
}

variable "email" {
  description = "Email for Let's Encrypt registration"
  type        = string
}

variable "do_token" {
  description = "DigitalOcean API token (DNS challenge; DO_AUTH_TOKEN in pod)"
  type        = string
  sensitive   = true
}
