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
        params = {
          "server.insecure" = true
        }
        # Repository credential for the PRIVATE deployment repo, so Argo CD can read it. The chart
        # renders this into a repository Secret in the argocd namespace (no separate secret/ordering).
        repositories = var.deploy_repo_pat == "" ? {} : {
          bizquery-deployment = {
            url      = var.deploy_repo_url
            type     = "git"
            name     = "bizquery-platform-deployment"
            username = "x-access-token"
            password = var.deploy_repo_pat
          }
        }
      }
      server = {
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled          = true
          ingressClassName = "traefik"
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints"        = "websecure"
            "traefik.ingress.kubernetes.io/router.tls"                = "true"
            "traefik.ingress.kubernetes.io/router.tls.certresolver"   = "letsencrypt"
            "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = var.domain_name
            "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${var.domain_name}"
          }
          hosts    = ["argocd.${var.domain_name}"]
          paths    = ["/"]
          pathType = "Prefix"
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
