resource "kubernetes_role_binding" "sync_secret_to_kong" {
  metadata {
    name      = "sync-secret-to-kong"
    namespace = "kong"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.secret_syncer.metadata[0].name
    namespace = "kong"
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role.manage_secrets.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}
