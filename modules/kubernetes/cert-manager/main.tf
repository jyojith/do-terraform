resource "kubernetes_secret" "do_dns_token" {
  metadata {
    name      = "do-dns-token"
    namespace = "cert-manager"
  }

  data = {
    "access-token" = var.do_token
  }

  type = "Opaque"
}


resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.14.3"

  create_namespace = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]
}
