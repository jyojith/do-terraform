variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for DNS records"
  type        = string
}

variable "dns_records" {
  description = "DNS A records to point at Traefik. Keys are record names such as @, argocd, api."
  type = map(object({
    ttl = optional(number, 300)
  }))
}

variable "region" {
  description = "DigitalOcean region (passed through for consistency)"
  type        = string
}

variable "traefik_lb_ip" {
  description = "Traefik LoadBalancer IP"
  type        = string
}
