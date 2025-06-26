resource "kubernetes_role_binding" "sync_secret_access" {
  metadata {
    name      = "secret-syncer-binding"
    namespace = "cert-manager"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "secret-syncer"
    namespace = "kong"
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role.read_certs.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}
