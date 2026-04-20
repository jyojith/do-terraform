module "argocd" {
  source = "${local.repo_root}/modules/kubernetes/argocd"

  domain_name                = var.domain_name
  repo_url                   = var.repo_url
  branch                     = var.branch
  manifests_path             = var.manifests_path
  env                        = var.env
  app_namespace              = var.app_namespace
  argocd_namespace           = "argocd"
  argocd_admin_password_hash = var.argocd_admin_password_hash
}
