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
  }
}

provider "digitalocean" {
  token = var.do_token
}


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
    module.cluster.cluster_urn,
    module.network.reserved_ip_urn
  ]
}


provider "kubernetes" {
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

# Kubernetes cluster module
module "cluster" {
  source      = "./modules/cluster"
  do_token    = var.do_token
  do_region   = var.do_region
  name        = var.name
  node_count  = var.node_count
  node_size   = var.node_size
  k8s_version = var.k8s_version

  depends_on = [module.network]
}

# Shared Reserved IP + DNS network module
module "network" {
  source      = "./modules/network"
  domain_name = var.domain_name
  region      = var.do_region
}

# ArgoCD deployment
module "argocd" {
  source           = "./modules/argocd"
  domain_name      = var.domain_name
  reserved_ip      = module.network.reserved_ip
  repo_url         = var.repo_url
  branch           = var.branch
  manifests_path   = var.manifests_path
  env              = var.env
  app_namespace    = var.app_namespace
  argocd_namespace = var.argocd_namespace
  argocd_admin_password_hash = var.argocd_admin_password_hash

  depends_on = [module.cluster, module.cert_manager, module.kong, module.network]
}


# Kong ingress controller
module "kong" {
  source      = "./modules/kong"
  reserved_ip = module.network.reserved_ip
  domain_name = var.domain_name

  depends_on = [module.cluster, module.cert_manager, module.network]
}

# Cert-manager
module "cert_manager" {
  source = "./modules/cert-manager"

  depends_on = [module.cluster, module.network]
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
