variable "region" {
  description = "DigitalOcean region for the reserved IP"
  type        = string
}

variable "domain_name" {
  description = "The root domain to configure DNS records for"
  type        = string
}

variable "dns_records" {
  description = "DNS A records to point at Traefik. Keys are record names such as @, argocd, api."
  type = map(object({
    ttl = optional(number, 300)
  }))
}

variable "traefik_lb_ip" {
  description = "Traefik LoadBalancer IP"
  type        = string
}
