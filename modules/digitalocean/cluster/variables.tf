variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "DigitalOcean region slug"
  type        = string
}

variable "name" {
  description = "Cluster name"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the Kubernetes cluster"
  type        = number
}

variable "node_size" {
  description = "Droplet size for Kubernetes nodes"
  type        = string
}

variable "k8s_version" {
  description = "DigitalOcean Kubernetes version"
  type        = string
}
