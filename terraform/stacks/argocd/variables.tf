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

variable "k8s_host" {
  description = "Kubernetes API server URL (from DOKS cluster endpoint)"
  type        = string
}

variable "k8s_token" {
  description = "Kubernetes bearer token for the cluster"
  type        = string
  sensitive   = true
}

variable "k8s_cluster_ca_certificate" {
  description = "Cluster CA cert from DOKS kube_config (base64-encoded PEM, or PEM text)"
  type        = string
  sensitive   = true
}
