resource "helm_release" "kubed" {
  name             = "kubed"
  repository       = "https://charts.appscode.com/stable/"
  chart            = "kubed"
  version          = "v0.12.0"
  namespace        = "kube-system"
  create_namespace = true
}
