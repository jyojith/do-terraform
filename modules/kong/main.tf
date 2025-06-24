resource "helm_release" "kong" {
  name             = "kong"
  namespace        = "kong"
  repository       = "https://charts.konghq.com"
  chart            = "kong"
  version          = "2.34.0" # or latest
  create_namespace = true

  skip_crds = true # 💡 This avoids the CRD ownership conflict

  set = [
    {
      name  = "proxy.type"
      value = "LoadBalancer"
    },
    {
      name  = "proxy.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-ip"
      value = var.reserved_ip
    },
    {
      name  = "ingressController.installCRDs"
      value = "true"
    }
  ]
}
