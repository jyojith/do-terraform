output "kong_lb_ip" {
  value = data.kubernetes_service.kong_proxy.status[0].load_balancer[0].ingress[0].ip
}
