module "traefik" {
  source = "${local.repo_root}/modules/kubernetes/traefik"

  domain_name = var.domain_name
  email       = var.email
  do_token    = var.do_token

  providers = {
    kubernetes     = kubernetes
    kubernetes.k8s = kubernetes.k8s
  }
}
