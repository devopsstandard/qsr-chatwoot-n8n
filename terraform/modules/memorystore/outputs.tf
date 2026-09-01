output "host" {
  value       = google_redis_instance.redis.host
  description = "Private IP address of Memorystore Redis instance"
}

output "port" {
  value       = google_redis_instance.redis.port
  description = "Port number of Redis instance"
}

output "secret_id" {
  value       = google_secret_manager_secret.redis_secret.secret_id
  description = "Secret ID for Redis auth credentials"
}
