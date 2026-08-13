# DO Managed PostgreSQL for the app database — replaces the self-hosted in-cluster StatefulSet
# (bizquery-platform-deployment/dev/postgres.yaml). Private-networked into the DOKS cluster's own
# VPC, with a firewall rule scoping access to that cluster only — never publicly reachable.
resource "digitalocean_database_cluster" "postgres" {
  name       = var.name
  engine     = "pg"
  version    = var.pg_version
  size       = var.size
  region     = var.do_region
  node_count = var.node_count

  private_network_uuid = var.vpc_uuid
}

# Dedicated least-privilege app user/database inside the cluster (not doadmin/defaultdb) — matches
# the self-hosted setup's bqp/bqp today, so the app needs no changes beyond the connection string.
resource "digitalocean_database_db" "app" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.db_name
}

resource "digitalocean_database_user" "app" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.db_user
}

# Only the DOKS cluster's own nodes may reach this database.
resource "digitalocean_database_firewall" "postgres" {
  cluster_id = digitalocean_database_cluster.postgres.id

  rule {
    type  = "k8s"
    value = var.doks_cluster_id
  }
}
