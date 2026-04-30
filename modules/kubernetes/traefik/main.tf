terraform {
  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.11"
      configuration_aliases = [kubernetes.k8s]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
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

  # kubernetes_secret_v1 only supports `data` (per-key base64), not string_data.
  data = {
    "access-token" = base64encode(trimspace(var.do_token))
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
  timeout          = 600
  create_namespace = false
  take_ownership   = true
  # Avoid helm --wait races with LoadBalancer Services + CCM (seen as: services "traefik" not found).
  # Pods may still be starting; re-run apply if traefik_lb_ip is null until DO assigns the LB IP.
  wait             = false

  values = [local.traefik_values]

  depends_on = [kubernetes_secret_v1.do_dns]
}

# With wait = false, the LB Service may have no .status.loadBalancer until the cloud CCM assigns
# an IP. Without this delay, traefik_lb_ip is often null and Terragrunt dependency outputs are empty
# (dns stack fails: "no variable named dependency" / "detected no outputs").
resource "time_sleep" "wait_for_traefik_lb" {
  depends_on      = [helm_release.traefik]
  create_duration = "90s"
}

data "kubernetes_service_v1" "traefik_lb" {
  provider = kubernetes.k8s
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace_v1.traefik.metadata[0].name
  }

  depends_on = [time_sleep.wait_for_traefik_lb]
}
