module "cert_manager" {
  source          = "${local.repo_root}/modules/kubernetes/cert_manager"
  do_token        = var.do_token
  email           = var.email
  domain_name     = var.domain_name
  tls_secret_name = var.tls_secret_name
}
