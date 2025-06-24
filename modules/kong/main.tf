resource "helm_release" "kong" {
  name       = "kong"
  namespace  = "kong"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = "2.27.0"

  create_namespace = true

  set {
    name  = "proxy.type"
    value = "LoadBalancer"
  }

  set {
    name  = "proxy.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-ip"
    value = var.reserved_ip
  }

  set {
    name  = "ingressController.installCRDs"
    value = "true"
  }
}
