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
  default     = "k8s/apps"
}

# Namespace where the ArgoCD Application CR will be installed
variable "argocd_namespace" {
  type    = string
  default = "argocd"
}

# Namespace where the application will be deployed
variable "app_namespace" {
  type = string
}


variable "domain_name" {
  description = "Domain name for routing"
  type        = string
}
variable "argocd_admin_password_hash" {
  description = "BCrypt-hashed admin password for ArgoCD"
  type        = string
}
