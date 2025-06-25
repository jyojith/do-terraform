terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      configuration_aliases = [
        kubernetes.k8s
      ]
    }
  }
}
