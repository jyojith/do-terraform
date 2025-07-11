resource "kubernetes_storage_class_v1" "default" {
  metadata {
    name = var.storage_class_name
  }

  storage_provisioner = var.provisioner

  parameters = var.parameters

  reclaim_policy         = var.reclaim_policy
  volume_binding_mode    = var.volume_binding_mode
  allow_volume_expansion = var.allow_volume_expansion
}

resource "kubernetes_persistent_volume_claim" "default" {
  metadata {
    name      = var.pvc_name
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class_v1.default.metadata[0].name

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}
