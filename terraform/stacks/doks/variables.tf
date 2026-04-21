variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "Region to deploy DigitalOcean resources"
  type        = string
}

variable "project_name" {
  description = "Name of the DigitalOcean project"
  type        = string
}

variable "name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "node_count" {
  description = "Number of Kubernetes worker nodes"
  type        = number
}

variable "node_size" {
  description = "Size of Kubernetes nodes"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version to use"
  type        = string
}

variable "domain_name" {
  description = "Domain name registered in DigitalOcean"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}
