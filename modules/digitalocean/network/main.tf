data "kubernetes_service" "traefik_lb" {
  provider = kubernetes.k8s
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
}

resource "digitalocean_record" "root_domain" {
  domain = var.domain_name
  type   = "A"
  name   = "@"
  value  = var.traefik_lb_ip
  ttl    = 60
}

resource "digitalocean_record" "wildcard" {
  domain = var.domain_name
  type   = "A"
  name   = "*"
  value  = var.traefik_lb_ip
  ttl    = 60
}

resource "digitalocean_record" "argocd" {
  domain = var.domain_name
  type   = "A"
  name   = "argocd"
  value  = var.traefik_lb_ip
  ttl    = 300
}

resource "digitalocean_record" "traefik" {
  domain = var.domain_name
  type   = "A"
  name   = "traefik"
  value  = var.traefik_lb_ip
  ttl    = 60
}
