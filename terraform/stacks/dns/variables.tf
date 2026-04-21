variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for DNS records"
  type        = string
}

variable "region" {
  description = "DigitalOcean region (passed through for consistency)"
  type        = string
}

variable "traefik_lb_ip" {
  description = "Traefik LoadBalancer IP"
  type        = string
}
