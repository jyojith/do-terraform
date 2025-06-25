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
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  host                   = module.cluster.endpoint
  token                  = module.cluster.token
  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
}

provider "kubernetes" {
  alias = "k8s"
  host                   = module.cluster.endpoint
  token                  = module.cluster.token
  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = module.cluster.endpoint
    token                  = module.cluster.token
    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
  }
}

# Create DO project
resource "digitalocean_project" "main" {
  name        = var.project_name
  description = "BizQuery ${terraform.workspace} infrastructure"
  purpose     = "Web Application Hosting"
  environment = {
    dev     = "Development"
    staging = "Staging"
    prod    = "Production"
  }[terraform.workspace]
}

resource "digitalocean_project_resources" "default" {
  project = digitalocean_project.main.id

  resources = [
    module.cluster.cluster_urn
    # DNS records will automatically be tracked by DigitalOcean UI
  ]
}

# Kubernetes Cluster
module "cluster" {
  source      = "./modules/cluster"
  do_token    = var.do_token
  do_region   = var.do_region
  name        = var.name
  node_count  = var.node_count
  node_size   = var.node_size
  k8s_version = var.k8s_version
}

# Kong Ingress Controller
module "kong" {
  source      = "./modules/kong"
  domain_name = var.domain_name

  depends_on = [module.cluster, module.cert_manager]
}

# Cert-Manager
module "cert_manager" {
  source = "./modules/cert-manager"

  depends_on = [module.cluster]
}

# DigitalOcean DNS (based on Kong LoadBalancer IP)
module "network" {
  source      = "./modules/network"
  domain_name = var.domain_name
  region      = var.do_region

  providers = {
    kubernetes.k8s = kubernetes.k8s
  }

  depends_on = [module.kong]
}

# ArgoCD Installation
module "argocd" {
  source                    = "./modules/argocd"
  domain_name               = var.domain_name
  repo_url                  = var.repo_url
  branch                    = var.branch
  manifests_path            = var.manifests_path
  env                       = var.env
  app_namespace             = var.app_namespace
  argocd_namespace          = "argocd"
  argocd_admin_password_hash = var.argocd_admin_password_hash

  depends_on = [module.cluster, module.cert_manager, module.kong, module.network]
}


locals {
  k8s_path = "${path.root}/k8s/${var.env}"
}
