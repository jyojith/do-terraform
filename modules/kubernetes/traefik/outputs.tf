output "traefik_lb_ip" {
  description = "The LoadBalancer IP assigned to the Traefik service"
  value       = try(data.kubernetes_service.traefik_lb.status[0].load_balancer[0].ingress[0].ip, null)
}
