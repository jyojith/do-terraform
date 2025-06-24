variable "reserved_ip" {
  description = "Shared reserved IP for ArgoCD LoadBalancer"
  type        = string
}

variable "domain_name" {
  description = "Domain name for routing"
  type        = string
}
