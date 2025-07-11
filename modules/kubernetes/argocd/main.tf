resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.5"

  create_namespace = true

  values = [
    yamlencode({
      configs = {
        secret = {
          argocdServerAdminPassword = var.argocd_admin_password_hash
        }
        cm = {
          "url" = "https://argocd.${var.domain_name}"
        }
      }
      server = {
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]
}



resource "helm_release" "env_manifests_app" {
  name       = "bizquery-${var.env}-manifests"
  namespace  = var.argocd_namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "1.4.1"

  create_namespace = false

  depends_on = [helm_release.argocd]

  values = [
    yamlencode({
      applications = [
        {
          name      = "bizquery-${var.env}-manifests"
          namespace = var.argocd_namespace
          project   = "default"

          source = {
            repoURL        = var.repo_url
            targetRevision = var.branch
            path           = var.manifests_path
          }

          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = var.app_namespace
          }

          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      ]
    })
  ]
}
