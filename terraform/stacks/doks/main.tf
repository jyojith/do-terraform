provider "digitalocean" {
  token = var.do_token
}

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

module "cluster" {
  source      = "${local.repo_root}/modules/digitalocean/cluster"
  do_token    = var.do_token
  do_region   = var.do_region
  name        = var.name
  node_count  = var.node_count
  node_size   = var.node_size
  k8s_version = var.k8s_version
}

resource "digitalocean_project_resources" "default" {
  project = digitalocean_project.main.id
  resources = [
    module.cluster.cluster_urn,
    digitalocean_domain.this.urn
  ]
}
