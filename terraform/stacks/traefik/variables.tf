variable "domain_name" {
  description = "Apex domain for ACME and routes"
  type        = string
}

variable "email" {
  description = "Email for Let's Encrypt (Traefik ACME); must be a real mailbox (no placeholders)"
  type        = string

  validation {
    condition     = length(trimspace(var.email)) > 5 && strcontains(var.email, "@") && trimspace(var.email) != "a@b.c"
    error_message = "Set a real ACME contact email in environments/dev/env.hcl (locals.email). Placeholder a@b.c is rejected by Let's Encrypt."
  }
}

variable "do_token" {
  description = "DigitalOcean API token for DNS-01 challenge"
  type        = string
  sensitive   = true
}

variable "k8s_kubeconfig_yaml" {
  description = "Full kubeconfig YAML from DOKS (module output kubeconfig / raw_config)"
  type        = string
  sensitive   = true
}
