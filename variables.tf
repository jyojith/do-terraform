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

variable "name" {
  description = "Name for the cluster resources"
  type        = string
}

variable "project_name" {
  description = "The name of the DigitalOcean project"
  type        = string
}

variable "repo_url" {
  description = "Git repository URL containing Kubernetes manifests"
  type        = string
}

variable "branch" {
  description = "Git branch to deploy from"
  type        = string
  default     = "main"
}

variable "manifests_path" {
  description = "Path to manifests in the repository"
  type        = string
  default     = "k8s/apps"
}

variable "app_namespace" {
  description = "Namespace where the application is deployed"
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace where ArgoCD apps are created"
  type        = string
  default     = "argocd"
}
variable "argocd_admin_password_hash" {
  description = "BCrypt-hashed admin password for ArgoCD"
  type        = string
}
