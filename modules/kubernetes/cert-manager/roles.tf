resource "kubernetes_role" "read_certs" {
  metadata {
    name      = "read-certs"
    namespace = "cert-manager"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
}
