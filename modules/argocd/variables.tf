variable "env" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "repo_url" {
  description = "Git repository URL containing Kubernetes manifests"
  type        = string
}

variable "branch" {
  description = "Git branch ArgoCD should track"
  type        = string
  default     = "main"
}

variable "manifests_path" {
  description = "Path to manifest folder relative to the repo root"
  type        = string
}

variable "k8s_namespace" {
  description = "Namespace to deploy the manifests into"
  type        = string
  default     = "default"
}

variable "reserved_ip" {
  description = "Shared reserved IP for ArgoCD LoadBalancer"
  type        = string
}

variable "domain_name" {
  description = "Domain name for routing"
  type        = string
}
