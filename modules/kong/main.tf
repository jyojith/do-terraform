resource "helm_release" "kong" {
  name             = "kong"
  namespace        = "kong"
  repository       = "https://charts.konghq.com"
  chart            = "kong"
  version          = "2.34.0"
  create_namespace = true

  skip_crds = true

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
    },
    {
      name  = "proxy.tls.enabled"
      value = "true"
    },
    {
      name  = "proxy.tls.existingSecret"
      value = "bizquery-wildcard-tls"
    },
    {
      name  = "manager.enabled"
      value = "true"
    },
    {
      name  = "manager.type"
      value = "ClusterIP"
    },
    {
      name  = "manager.ingress.enabled"
      value = "true"
    },
    {
      name  = "manager.ingress.ingressClassName"
      value = "kong"
    },
    {
      name  = "manager.ingress.hostname"
      value = "kong.bizquery.dev"
    },
    {
      name  = "manager.ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "letsencrypt-prod"
    },
    {
      name  = "manager.ingress.tls[0].hosts[0]"
      value = "kong.bizquery.dev"
    },
    {
      name  = "manager.ingress.tls[0].secretName"
      value = "bizquery-wildcard-tls"
    }
  ]
}
