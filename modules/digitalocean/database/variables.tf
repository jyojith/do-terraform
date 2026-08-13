variable "do_region" {
  description = "DigitalOcean region slug"
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
  description = "VPC UUID to place the database cluster in (private networking, no public exposure)"
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
  description = "Application database user (least-privilege, not doadmin)"
  type        = string
  default     = "bqp"
}
