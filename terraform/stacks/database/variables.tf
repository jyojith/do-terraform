variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "Region to deploy the database cluster in"
  type        = string
}

variable "project_name" {
  description = "Name of the existing DigitalOcean project (owned by the doks stack) to register this cluster under"
  type        = string
}

variable "name" {
  description = "Database cluster name"
  type        = string
}

variable "size" {
  description = "DigitalOcean database droplet size slug"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "node_count" {
  description = "Number of nodes in the database cluster"
  type        = number
  default     = 1
}

variable "pg_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
}

variable "vpc_uuid" {
  description = "VPC UUID to place the database cluster in (the DOKS cluster's own VPC)"
  type        = string
}

variable "doks_cluster_id" {
  description = "DOKS cluster ID allowed to reach the database (firewall rule, type = k8s)"
  type        = string
}

variable "db_name" {
  description = "Application database name"
  type        = string
  default     = "bqp"
}

variable "db_user" {
  description = "Application database user"
  type        = string
  default     = "bqp"
}
