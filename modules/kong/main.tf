resource "helm_release" "kong" {
  name       = "kong"
  namespace  = "kong"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = "2.33.0"

  create_namespace = true

  set {
    name  = "ingressController.installCRDs"
    value = true
  }

  set {
    name  = "proxy.type"
    value = "LoadBalancer"
  }

  set {
    name  = "proxy.loadBalancerIP"
    value = var.kong_reserved_ip
  }

  set {
    name  = "proxy.annotations.service\.beta\.kubernetes\.io/do-loadbalancer-ip"
    value = var.kong_reserved_ip
  }
}
