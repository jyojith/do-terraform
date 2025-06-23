# infra/main.tf

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11"
    }
    kubernetes-manifest = {
      source  = "hashicorp/kubernetes-manifest"
      version = ">= 0.9.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.main.endpoint
  token                  = digitalocean_kubernetes_cluster.main.kube_config[0].token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = digitalocean_kubernetes_cluster.main.endpoint
    token                  = digitalocean_kubernetes_cluster.main.kube_config[0].token
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
  }
}

# Kubernetes cluster module
module "cluster" {
  source      = "./modules/cluster"
  do_token    = var.do_token
  region      = var.do_region
  node_count  = var.node_count
  node_size   = var.node_size
  k8s_version = var.k8s_version
}

# Shared Reserved IP + DNS network module
module "network" {
  source      = "./modules/network"
  domain_name = var.domain_name
  region      = var.do_region
}

# ArgoCD deployment
module "argocd" {
  source             = "./modules/argocd"
  reserved_ip        = module.network.reserved_ip
  domain_name        = var.domain_name
}

# Kong ingress controller
module "kong" {
  source             = "./modules/kong"
  reserved_ip        = module.network.reserved_ip
  domain_name        = var.domain_name
}

# Cert-manager
module "cert_manager" {
  source = "./modules/cert-manager"
}

# Load Kubernetes manifests for current environment
variable "env" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

locals {
  k8s_path = "${path.root}/k8s/${var.env}"
}

resource "kubernetes_manifest" "clusterissuer" {
  manifest = yamldecode(file("${local.k8s_path}/clusterissuer.yaml"))
}

resource "kubernetes_manifest" "argocd_ingress" {
  manifest = yamldecode(file("${local.k8s_path}/ingress-argocd.yaml"))
}

resource "kubernetes_manifest" "app_ingress" {
  manifest = yamldecode(file("${local.k8s_path}/ingress-app.yaml"))
}
