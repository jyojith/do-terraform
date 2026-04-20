terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.11"
      configuration_aliases = [kubernetes.k8s]
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11"
    }
  }
}
