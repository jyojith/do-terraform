resource "helm_release" "env_manifests_app" {
  name       = "bizquery-${var.env}-manifests"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "1.4.1"

  create_namespace = false

  values = [
    yamlencode({
      applications = [
        {
          name      = "bizquery-${var.env}-manifests"
          namespace = "argocd"
          project   = "default"

          source = {
            repoURL        = var.repo_url
            targetRevision = var.branch
            path           = var.manifests_path
          }

          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = var.k8s_namespace
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
