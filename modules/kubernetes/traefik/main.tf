terraform {
  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.11"
      configuration_aliases = [kubernetes.k8s]
    }
  }
}

resource "kubernetes_namespace_v1" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "kubernetes_secret_v1" "do_dns" {
  metadata {
    name      = "traefik-do-dns"
    namespace = kubernetes_namespace_v1.traefik.metadata[0].name
  }

  data = {
    "access-token" = base64encode(var.do_token)
  }

  type = "Opaque"
}

locals {
  traefik_values = templatefile("${path.module}/values.yaml.tpl", {
    domain_name = var.domain_name
    email       = var.email
  })
}

resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = kubernetes_namespace_v1.traefik.metadata[0].name
  chart            = "traefik"
  version          = "25.0.0"
  repository       = "https://helm.traefik.io/traefik"
  timeout          = 900
  create_namespace = false
  take_ownership   = true

  values = [local.traefik_values]

  depends_on = [kubernetes_secret_v1.do_dns]
}

data "kubernetes_service_v1" "traefik_lb" {
  provider = kubernetes.k8s
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace_v1.traefik.metadata[0].name
  }

  depends_on = [helm_release.traefik]
}
