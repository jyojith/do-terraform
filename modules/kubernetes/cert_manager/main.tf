resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.4"

  create_namespace = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]
}

resource "kubernetes_secret" "do_dns" {
  metadata {
    name      = "do-dns"
    namespace = "cert-manager"
  }

  data = {
    "access-token" = var.do_token
  }

  type = "Opaque"
}

resource "null_resource" "wait_for_cert_manager_crds" {
  depends_on = [helm_release.cert_manager]

  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Waiting for cert-manager CRDs to register..."
      for crd in clusterissuers.cert-manager.io certificates.cert-manager.io; do
        for i in {1..30}; do
          if kubectl get crd $crd > /dev/null 2>&1; then
            echo "✅ CRD $crd is available"
            break
          fi
          echo "Waiting for $crd..."
          sleep 2
        done
      done
    EOT
  }
}



resource "kubernetes_manifest" "cluster_issuer" {
  manifest = yamldecode(templatefile("${path.module}/templates/cluster_issuer.yaml.tpl", {
    email       = var.email,
    secret_name = "do-dns"
  }))

  depends_on = [null_resource.wait_for_cert_manager_crds]
}

resource "kubernetes_manifest" "wildcard_cert" {
  manifest = yamldecode(templatefile("${path.module}/templates/wildcard_cert.yaml.tpl", {
    domain_name = var.domain_name,
    issuer_name = "letsencrypt-prod",
    secret_name = var.tls_secret_name
  }))

  depends_on = [null_resource.wait_for_cert_manager_crds]
}
