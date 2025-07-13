terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.0"
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.11"
      configuration_aliases = [kubernetes.k8s]
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
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
  alias                  = "k8s"
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
  description = "BizQuery ${var.env} infrastructure"
  purpose     = "Web Application Hosting"
  environment = {
    dev     = "Development"
    staging = "Staging"
    prod    = "Production"
  }[var.env]
}

resource "digitalocean_domain" "this" {
  name = var.domain_name
}

resource "digitalocean_project_resources" "default" {
  project = digitalocean_project.main.id
  resources = [
    module.cluster.cluster_urn,
    digitalocean_domain.this.urn
  ]
}


# Kubernetes Cluster
module "cluster" {
  source      = "./modules/digitalocean/cluster"
  do_token    = var.do_token
  do_region   = var.do_region
  name        = var.name
  node_count  = var.node_count
  node_size   = var.node_size
  k8s_version = var.k8s_version
}

module "cert_manager" {
  source          = "./modules/kubernetes/cert_manager"
  do_token        = var.do_token
  email           = var.email
  domain_name     = var.domain_name
  tls_secret_name = var.tls_secret_name

  depends_on = [module.cluster]
}

# Traefik Ingress
module "traefik" {
  source      = "./modules/kubernetes/traefik"
  domain_name = var.domain_name

  providers = {
    kubernetes     = kubernetes
    kubernetes.k8s = kubernetes.k8s
  }

  depends_on = [module.cluster]
}


# DigitalOcean DNS
module "network" {
  source      = "./modules/digitalocean/network"
  domain_name = var.domain_name
  region      = var.do_region

  traefik_lb_ip = module.traefik.traefik_lb_ip

  providers = {
    kubernetes.k8s = kubernetes.k8s
  }

  depends_on = [module.traefik, digitalocean_domain.this]
}

# ArgoCD
module "argocd" {
  source                     = "./modules/kubernetes/argocd"
  domain_name                = var.domain_name
  repo_url                   = var.repo_url
  branch                     = var.branch
  manifests_path             = var.manifests_path
  env                        = var.env
  app_namespace              = var.app_namespace
  argocd_namespace           = "argocd"
  argocd_admin_password_hash = var.argocd_admin_password_hash

  depends_on = [module.cluster, module.network, module.traefik, module.cert_manager]
}

locals {
  k8s_path = "${path.root}/k8s/${var.env}"
}
