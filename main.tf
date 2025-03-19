terraform {
  backend "remote" {
    organization = "jyojith-starthack"

    workspaces {
      name = "starthack-do"
    }
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.16.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_project" "k8s_challenge" {
  name        = "k8s-challenge"
  description = "Start hack 2025 cluster"
  purpose     = "Just trying out DigitalOcean"
  environment = "Development"

  resources = [
    digitalocean_kubernetes_cluster.starthack.urn
  ]
}

resource "digitalocean_vpc" "k8s" {
  name   = "k8s-vpc"
  region = "fra1"

  timeouts {
    delete = "4m"
  }
}

data "digitalocean_kubernetes_versions" "prefix" {
  version_prefix = "1.32."
}

resource "digitalocean_kubernetes_cluster" "starthack" {
  name         = "starthack"
  region       = "fra1"
  auto_upgrade = true
  version      = data.digitalocean_kubernetes_versions.prefix.latest_version

  vpc_uuid = digitalocean_vpc.k8s.id

  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }

  node_pool {
    name       = "application-pool"
    size       = "s-2vcpu-2gb"
    node_count = 1
  }
}

provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.starthack.endpoint
  token                  = digitalocean_kubernetes_cluster.starthack.kube_config[0].token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.starthack.kube_config[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = digitalocean_kubernetes_cluster.starthack.endpoint
  token                  = digitalocean_kubernetes_cluster.starthack.kube_config[0].token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.starthack.kube_config[0].cluster_ca_certificate)
  load_config_file       = false
}

resource "digitalocean_domain" "jyojith_site" {
  name = "jyojith.site"
}

resource "digitalocean_record" "ingress" {
  domain = digitalocean_domain.jyojith_site.name
  type   = "A"
  name   = "*.jyojith.site"
  value  = digitalocean_kubernetes_cluster.starthack.endpoint
  ttl    = 300
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

resource "kubernetes_secret" "argocd_admin_password" {
  metadata {
    name      = "argocd-secret"
    namespace = "argocd"
  }

  data = {
    admin.password      = var.argocd_admin_password
    admin.passwordMtime = timestamp()
  }

  type = "Opaque"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argocd_admin_password
  }
}

resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = "app-ingress"
    namespace = "default"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["app.jyojith.site", "argocd.jyojith.site"]
      secret_name = "app-tls"
    }

    rule {
      host = "app.jyojith.site"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "myapp-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = "argocd.jyojith.site"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

variable "do_token" {
  default = DIGITALOCEAN_TOKEN
}

variable "argocd_admin_password" {
  default = ARGOCD_ADMIN_PASS
}
