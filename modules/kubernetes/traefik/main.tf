terraform {
  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.11"
      configuration_aliases = [kubernetes.k8s]
    }
  }
}

data "template_file" "traefik_values" {
  template = file("${path.module}/values.yaml.tpl")

  vars = {
    domain_name     = var.domain_name
    tls_secret_name = var.tls_secret_name
  }
}

resource "helm_release" "traefik" {
  name       = "traefik"
  namespace  = "traefik"
  chart      = "traefik"
  version    = "25.0.0"
  repository = "https://helm.traefik.io/traefik"
  timeout    = 300

  create_namespace = true

  values = [data.template_file.traefik_values.rendered]
}

data "kubernetes_service" "traefik_lb" {
  provider = kubernetes.k8s
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }

  depends_on = [helm_release.traefik]
}
