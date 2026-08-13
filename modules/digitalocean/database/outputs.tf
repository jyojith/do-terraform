output "cluster_id" {
  value = digitalocean_database_cluster.postgres.id
}

output "urn" {
  value = digitalocean_database_cluster.postgres.urn
}

output "host" {
  value = digitalocean_database_cluster.postgres.private_host
}

output "port" {
  value = digitalocean_database_cluster.postgres.port
}

output "database" {
  value = digitalocean_database_db.app.name
}

output "user" {
  value = digitalocean_database_user.app.name
}

output "password" {
  value     = digitalocean_database_user.app.password
  sensitive = true
}

# App-ready DSN, private-network host, sslmode=require (DO managed PG mandates TLS; psycopg accepts
# sslmode as a plain DSN query param). BQP_DATABASE_URL is set to exactly this value.
output "database_url" {
  value     = "postgresql+psycopg://${digitalocean_database_user.app.name}:${digitalocean_database_user.app.password}@${digitalocean_database_cluster.postgres.private_host}:${digitalocean_database_cluster.postgres.port}/${digitalocean_database_db.app.name}?sslmode=require"
  sensitive = true
}

# The cluster's own built-in admin connection (DO's default user, typically "doadmin") — needed
# once, one-off, to GRANT the app user rights on the public schema (PG15+ no longer grants that
# implicitly) before the data migration restore. Not used by the app itself.
output "admin_uri" {
  value     = digitalocean_database_cluster.postgres.private_uri
  sensitive = true
}
