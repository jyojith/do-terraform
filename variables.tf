variable "argocd_reserved_ip" {
  description = "The reserved IP address to assign to ArgoCD service"
  type        = string
}

variable "kong_reserved_ip" {
  description = "The reserved IP address to assign to Kong proxy"
  type        = string
}

variable "domain_name" {
  description = "Environment-specific base domain"
  type        = string
}
