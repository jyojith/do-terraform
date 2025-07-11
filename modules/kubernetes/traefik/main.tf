terraform {
  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.11"
      configuration_aliases = [kubernetes.k8s]
    }
  }
}

resource "kubernetes_secret_v1" "do_token" {
  metadata {
    name      = "do-dns-secret"
    namespace = var.namespace
  }

  data = {
    DO_AUTH_TOKEN = var.do_token
  }

  type = "Opaque"
}

data "template_file" "traefik_values" {
  template = file("${path.module}/values.yaml.tpl")

  vars = {
    domain_name        = var.domain_name
    pvc_name           = var.pvc_name
    storage_class_name = var.storage_class_name
  }
}

resource "helm_release" "traefik" {
  name       = "traefik"
  namespace  = "traefik"
  chart      = "traefik"
  version    = "25.0.0"
  repository = "https://helm.traefik.io/traefik"
  timeout    = 300

  depends_on = [
    kubernetes_secret_v1.do_token
  ]

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
