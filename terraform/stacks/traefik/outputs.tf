output "traefik_lb_ip" {
  description = "LoadBalancer IP assigned to the Traefik service"
  value       = module.traefik.traefik_lb_ip
}
