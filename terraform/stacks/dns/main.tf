provider "digitalocean" {
  token = var.do_token
}

module "network" {
  source = "${local.repo_root}/modules/digitalocean/network"

  domain_name   = var.domain_name
  region        = var.region
  traefik_lb_ip = var.traefik_lb_ip
}
