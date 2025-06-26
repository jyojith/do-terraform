resource "kubernetes_service_account" "secret_syncer" {
  metadata {
    name      = "secret-syncer"
    namespace = "kong"
  }
}
