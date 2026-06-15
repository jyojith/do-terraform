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

variable "k8s_kubeconfig_yaml" {
  description = "Full kubeconfig YAML from DOKS (module output kubeconfig / raw_config)"
  type        = string
  sensitive   = true
}

variable "do_model_access_key" {
  description = "DigitalOcean Gradient AI model access key — drives BQP chat + embeddings (inference.do-ai.run)"
  type        = string
  sensitive   = true
}

variable "ghcr_username" {
  description = "GitHub username for the GHCR image pull secret"
  type        = string
  default     = ""
}

variable "ghcr_pat" {
  description = "GitHub PAT with read:packages — for the cluster to pull the private bizquery image"
  type        = string
  sensitive   = true
  default     = ""
}
