variable "domain_name" {
  description = "Apex domain (ACME DNS-01 and routes)"
  type        = string
}

variable "email" {
  description = "Email for Let's Encrypt registration"
  type        = string
}

variable "do_token" {
  description = "DigitalOcean API token with access to manage DNS for the ACME domain (lego: DO_AUTH_TOKEN in pod; must not be read-only for domains)."
  type        = string
  sensitive   = true
}
