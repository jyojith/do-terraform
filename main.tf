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

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
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

data "digitalocean_domain" "main" {
  name = var.domain_name
}

resource "digitalocean_project_resources" "default" {
  project = digitalocean_project.main.id
  resources = [
    module.cluster.cluster_urn,
    data.digitalocean_domain.main.urn
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

# Persistent Storage
module "storage" {
  source = "./modules/kubernetes/storage"

  storage_class_name     = "do-block-storage-${var.env}"
  provisioner            = "dobs.csi.digitalocean.com"
  parameters             = {}
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true

  pvc_name     = "traefik-acme"
  namespace    = "traefik"
  storage_size = "1Gi"

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [module.cluster, kubernetes_namespace.traefik]
}

# Traefik Ingress
module "traefik" {
  source      = "./modules/kubernetes/traefik"
  domain_name = var.domain_name
  do_token    = var.do_token
  namespace   = kubernetes_namespace.traefik.metadata[0].name

  pvc_name           = module.storage.pvc_name
  storage_class_name = module.storage.storage_class_name

  providers = {
    kubernetes     = kubernetes
    kubernetes.k8s = kubernetes.k8s
  }

  depends_on = [module.cluster, module.storage]
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

  depends_on = [module.traefik]
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

  depends_on = [module.cluster, module.network, module.traefik]
}

locals {
  k8s_path = "${path.root}/k8s/${var.env}"
}
