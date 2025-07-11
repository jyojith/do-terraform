variable "region" {
  description = "DigitalOcean region for the reserved IP"
  type        = string
}

variable "domain_name" {
  description = "The root domain to configure DNS records for"
  type        = string
}

variable "traefik_lb_ip" {
  description = "Traefik LoadBalancer IP"
  type        = string
}
