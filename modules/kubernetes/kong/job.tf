resource "kubernetes_job" "copy_tls_secret" {
  metadata {
    name      = "copy-wildcard-secret-to-kong"
    namespace = "kong"
  }

  spec {
    template {
      metadata {}
      spec {
        service_account_name = kubernetes_service_account.secret_syncer.metadata[0].name
        restart_policy       = "Never"

        container {
          name  = "copy"
          image = "bitnami/kubectl:1.29" # or another known version

          command = [
            "/bin/sh", "-c",
            <<-EOC
              kubectl get secret bizquery-wildcard-tls -n cert-manager -o yaml | \
              sed 's/namespace: cert-manager/namespace: kong/' | \
              kubectl apply -f -
            EOC
          ]
        }
      }
    }

    backoff_limit = 3
  }
}
