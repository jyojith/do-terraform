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

resource "start_hack_project" "k8s_starthack" {
  name        = "k8s-challenge"
  description = "Start hack 2025 cluster"
  purpose     = "Just trying out DigitalOcean"
  environment = "Development"

  resources = [
    start_hack_cluster.starthack.urn
  ]
}

resource "start_hack_vpc" "k8s" {
  name   = "k8s-vpc"
  region = "fra1"

  timeouts {
    delete = "4m"
  }
}

data "start_hack_versions" "prefix" {
  version_prefix = "1.29."
}

resource "start_hack_cluster" "starthack" {
  name         = "starthack"
  region       = "fra1"
  auto_upgrade = true
  version      = data.start_hack_versions.prefix.latest_version

  vpc_uuid = start_hack_vpc.k8s.id

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
  host  = start_hack_cluster.starthack.endpoint
  token = start_hack_cluster.starthack.kube_config[0].token
  cluster_ca_certificate = base64decode(
    start_hack_cluster.starthack.kube_config[0].cluster_ca_certificate
  )
}

provider "kubectl" {
  host  = start_hack_cluster.starthack.endpoint
  token = start_hack_cluster.starthack.kube_config[0].token
  cluster_ca_certificate = base64decode(
    start_hack_cluster.starthack.kube_config[0].cluster_ca_certificate
  )
  load_config_file = false
}

variable "superUserPassword" {}
variable "replicationUserPassword" {}


resource "kubernetes_secret" "starthack_secret" {
  metadata {
    name      = "mystarthack-secret"
    namespace = "default"
  }

  data = {
    superUserPassword       = var.superUserPassword
    replicationUserPassword = var.replicationUserPassword
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
