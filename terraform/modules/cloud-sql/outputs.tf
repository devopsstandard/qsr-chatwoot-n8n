output "instance_name" {
  value       = google_sql_database_instance.instance.name
  description = "The name of the Cloud SQL instance"
}

output "connection_name" {
  value       = google_sql_database_instance.instance.connection_name
  description = "Connection string formatted as project:region:instance"
}

output "private_ip_address" {
  value       = google_sql_database_instance.instance.private_ip_address
  description = "Private IP address of the Cloud SQL instance"
}

output "secret_id" {
  value       = google_secret_manager_secret.db_secret.secret_id
  description = "Secret Manager secret ID holding database credentials"
}
