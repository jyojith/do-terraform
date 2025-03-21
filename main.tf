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
      version = "~> 2.36.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
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

  depends_on = [null_resource.wait_for_k8s]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = "testing123"
  }

  depends_on = [helm_release.nginx_ingress]
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.nginx_ingress]
}

resource "digitalocean_record" "ingress" {
  domain = digitalocean_domain.jyojith_site.name
  type   = "A"
  name   = "*.jyojith.site"
  value  = data.kubernetes_service.nginx_ingress.status.0.load_balancer.0.ingress.0.ip
  ttl    = 300

  depends_on = [helm_release.nginx_ingress]
}

resource "null_resource" "wait_for_k8s" {
  depends_on = [digitalocean_kubernetes_cluster.starthack]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for Kubernetes API to become available..."
      for i in {1..30}; do
        kubectl get nodes && break
        echo "Retrying in 10 seconds..."
        sleep 10
      done
    EOT
  }
}
