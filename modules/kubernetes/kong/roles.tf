resource "kubernetes_role" "manage_secrets" {
  metadata {
    name      = "manage-secrets"
    namespace = "kong"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "create", "update", "delete"]
  }
}
