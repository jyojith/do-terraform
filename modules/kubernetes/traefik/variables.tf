variable "do_token" {
  description = "DigitalOcean API token for DNS challenge"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "The root domain to configure DNS records for"
  type        = string
}

variable "pvc_name" {
  description = "Name of the PVC to mount for ACME data"
  type        = string
}

variable "storage_class_name" {
  description = "StorageClass name to use for the PVC"
  type        = string
}

variable "namespace" {
  description = "The namespace in which to deploy Traefik"
  type        = string
}
