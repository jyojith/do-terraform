resource "kubernetes_secret" "do_dns" {
  metadata {
    name      = "digitalocean-dns"
    namespace = "traefik"
  }

  data = {
    "access-token" = base64encode(var.do_token)
  }

  type = "Opaque"
}
