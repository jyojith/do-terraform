variable "k8s_version" {
  description = "Kubernetes version for the cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
}

variable "node_size" {
  description = "Droplet size for nodes"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (like bizquery.dev)"
  type        = string
}

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "DigitalOcean region slug"
  type        = string
}
