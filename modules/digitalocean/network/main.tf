data "kubernetes_service" "kong_lb" {
  provider = kubernetes.k8s
  metadata {
    name      = "kong-kong-proxy"
    namespace = "kong"
  }
}


resource "digitalocean_domain" "this" {
  name = var.domain_name
}

resource "digitalocean_record" "root_domain" {
  domain = var.domain_name
  type   = "A"
  name   = "@"
  value  = data.kubernetes_service.kong_lb.status[0].load_balancer[0].ingress[0].ip
  ttl    = 60
}

resource "digitalocean_record" "wildcard" {
  domain = var.domain_name
  type   = "A"
  name   = "*"
  value  = data.kubernetes_service.kong_lb.status[0].load_balancer[0].ingress[0].ip
  ttl    = 60
}


resource "digitalocean_record" "argocd" {
  domain = digitalocean_domain.this.name
  type   = "A"
  name   = "argocd"
  value  = data.kubernetes_service.kong_lb.status[0].load_balancer[0].ingress[0].ip
  ttl    = 300
}

resource "digitalocean_record" "kong" {
  domain = var.domain_name
  type   = "A"
  name   = "kong"
  value  = var.kong_lb_ip # Replace with output if available
  ttl    = 60
}
