variable "region" {
  description = "DigitalOcean region for the reserved IP"
  type        = string
}

variable "domain_name" {
  description = "The root domain to configure DNS records for"
  type        = string
}

variable "kong_lb_ip" {
  type        = string
  description = "LoadBalancer IP of Kong proxy"
}
