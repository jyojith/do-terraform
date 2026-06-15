# Namespace + image-pull secret for the marketing website. Its image is a PRIVATE GHCR package, so
# the cluster needs ghcr-pull; there are no app secrets (static site). Mirrors the platform's
# ns/ghcr-pull and reuses the same ghcr PAT (var.ghcr_username/ghcr_pat). Terraform owns the namespace
# so the secret exists before pods start (the website manifests carry no namespace.yaml).
resource "kubernetes_namespace_v1" "website" {
  metadata {
    name = "bizquery-website"
  }
}

resource "kubernetes_secret_v1" "website_ghcr_pull" {
  metadata {
    name      = "ghcr-pull"
    namespace = kubernetes_namespace_v1.website.metadata[0].name
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = var.ghcr_username
          password = var.ghcr_pat
          auth     = base64encode("${var.ghcr_username}:${var.ghcr_pat}")
        }
      }
    })
  }
}
