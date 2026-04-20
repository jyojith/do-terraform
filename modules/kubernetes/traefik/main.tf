terraform {
  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.11"
      configuration_aliases = [kubernetes.k8s]
    }
  }
}

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "kubernetes_secret" "do_dns" {
  metadata {
    name      = "traefik-do-dns"
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }

  data = {
    "access-token" = var.do_token
  }

  type = "Opaque"
}

data "template_file" "traefik_values" {
  template = file("${path.module}/values.yaml.tpl")

  vars = {
    domain_name = var.domain_name
    email       = var.email
  }
}

resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = kubernetes_namespace.traefik.metadata[0].name
  chart            = "traefik"
  version          = "25.0.0"
  repository       = "https://helm.traefik.io/traefik"
  timeout          = 300
  create_namespace = false

  values = [data.template_file.traefik_values.rendered]

  depends_on = [kubernetes_secret.do_dns]
}

data "kubernetes_service" "traefik_lb" {
  provider = kubernetes.k8s
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }

  depends_on = [helm_release.traefik]
}
