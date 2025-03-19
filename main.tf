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
  host  = digitalocean_kubernetes_cluster.starthack.endpoint
  token = digitalocean_kubernetes_cluster.starthack.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.starthack.kube_config[0].cluster_ca_certificate
  )
}

provider "kubectl" {
  host  = digitalocean_kubernetes_cluster.starthack.endpoint
  token = digitalocean_kubernetes_cluster.starthack.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.starthack.kube_config[0].cluster_ca_certificate
  )
  load_config_file = false
}



resource "kubernetes_secret" "starthack_secret" {
  metadata {
    name      = "mystarthack-secret"
    namespace = "default"
  }

  type = "Opaque"
}

data "kubectl_path_documents" "docs" {
  pattern = "./manifests/*.yaml"
}

resource "kubectl_manifest" "kubegres" {
  for_each  = toset(data.kubectl_path_documents.docs.documents)
  yaml_body = each.value
}
