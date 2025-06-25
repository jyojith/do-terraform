resource "helm_release" "kong" {
  name             = "kong"
  namespace        = "kong"
  repository       = "https://charts.konghq.com"
  chart            = "kong"
  version          = "2.34.0"
  create_namespace = true
  skip_crds        = true

  values = [
    yamlencode({
      proxy = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/do-loadbalancer-ip" = var.reserved_ip
        }
      }

      ingressController = {
        installCRDs = true
      }

      manager = {
        enabled = true
        type    = "ClusterIP"
        ingress = {
          enabled = true
          ingressClassName = "kong"
          hostname          = "kong.${var.domain_name}"
          path              = "/"
          pathType          = "Prefix"
          annotations = {
            "konghq.com/strip-path" = "true"
          }
        }
      }
    })
  ]
}
