locals {
  _k8s_in             = trimspace(var.k8s_cluster_ca_certificate)
  _k8s_b64            = replace(replace(local._k8s_in, "\n", ""), " ", "")
  _k8s_is_input_pem   = startswith(local._k8s_in, "-----BEGIN")
  _k8s_decoded        = local._k8s_is_input_pem ? local._k8s_in : base64decode(local._k8s_b64)
  _k8s_is_decoded_pem = !local._k8s_is_input_pem && startswith(trimspace(local._k8s_decoded), "-----BEGIN")
  k8s_cluster_ca_pem = local._k8s_is_input_pem ? local._k8s_in : (
    local._k8s_is_decoded_pem ? trimspace(local._k8s_decoded) : <<-EOT
-----BEGIN CERTIFICATE-----
${base64encode(local._k8s_decoded)}
-----END CERTIFICATE-----
EOT
  )
}

provider "helm" {
  kubernetes = {
    host                   = var.k8s_host
    token                  = var.k8s_token
    cluster_ca_certificate = local.k8s_cluster_ca_pem
  }
}
