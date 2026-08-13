output "cluster_id" {
  value = module.database.cluster_id
}

output "host" {
  value = module.database.host
}

output "port" {
  value = module.database.port
}

output "database" {
  value = module.database.database
}

output "user" {
  value = module.database.user
}

output "password" {
  value     = module.database.password
  sensitive = true
}

output "database_url" {
  value     = module.database.database_url
  sensitive = true
}

output "admin_uri" {
  value     = module.database.admin_uri
  sensitive = true
}
