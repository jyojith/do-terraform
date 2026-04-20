variable "domain_name" {
  description = "Domain name for Argo CD URL"
  type        = string
}

variable "repo_url" {
  description = "Git repository containing Kubernetes manifests"
  type        = string
}

variable "branch" {
  description = "Git branch Argo CD should track"
  type        = string
}

variable "manifests_path" {
  description = "Path in the repo where app manifests are defined"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "app_namespace" {
  description = "Kubernetes namespace to deploy app resources"
  type        = string
}

variable "argocd_admin_password_hash" {
  description = "Pre-hashed Argo CD admin password (bcrypt)"
  type        = string
  sensitive   = true
}
