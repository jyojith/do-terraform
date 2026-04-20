module "traefik" {
  source = "${local.repo_root}/modules/kubernetes/traefik"

  domain_name     = var.domain_name
  tls_secret_name = var.tls_secret_name

  providers = {
    kubernetes     = kubernetes
    kubernetes.k8s = kubernetes.k8s
  }
}
