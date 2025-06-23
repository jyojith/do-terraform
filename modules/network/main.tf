resource "digitalocean_reserved_ip" "shared" {
  region = var.region
}

resource "digitalocean_domain" "this" {
  name = var.domain_name
}

resource "digitalocean_record" "root_a" {
  domain = digitalocean_domain.this.name
  type   = "A"
  name   = "@"
  value  = digitalocean_reserved_ip.shared.ip_address
  ttl    = 300
}

resource "digitalocean_record" "argocd" {
  domain = digitalocean_domain.this.name
  type   = "A"
  name   = "argocd"
  value  = digitalocean_reserved_ip.shared.ip_address
  ttl    = 300
}
