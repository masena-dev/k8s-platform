output "host" {
  description = "PostgreSQL server host"
  value       = ovh_cloud_project_database.postgresql.endpoints[0].domain
}

output "port" {
  description = "PostgreSQL server port"
  value       = ovh_cloud_project_database.postgresql.endpoints[0].port
}

output "database_name" {
  description = "Name of the application database"
  value       = ovh_cloud_project_database_database.app_db.name
}

output "username" {
  description = "PostgreSQL username"
  value       = ovh_cloud_project_database_postgresql_user.app_user.name
}

output "password" {
  description = "PostgreSQL password"
  value       = ovh_cloud_project_database_postgresql_user.app_user.password
  sensitive   = true
}
