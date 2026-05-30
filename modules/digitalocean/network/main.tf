moved {
  from = digitalocean_record.root_domain
  to   = digitalocean_record.records["@"]
}

moved {
  from = digitalocean_record.argocd
  to   = digitalocean_record.records["argocd"]
}

moved {
  from = digitalocean_record.traefik
  to   = digitalocean_record.records["traefik"]
}

resource "digitalocean_record" "records" {
  for_each = var.dns_records

  domain = var.domain_name
  type   = "A"
  name   = each.key
  value  = var.traefik_lb_ip
  ttl    = each.value.ttl
}
