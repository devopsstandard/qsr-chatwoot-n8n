resource "google_redis_instance" "redis" {
  name                   = "qsr-redis-${var.environment}"
  tier                   = var.environment == "prod" ? "STANDARD_HA" : "BASIC"
  memory_size_gb         = var.memory_size_gb
  region                 = var.region
  project                = var.project_id
  authorized_network     = var.network_id
  connect_mode           = "PRIVATE_SERVICE_ACCESS"
  redis_version          = var.redis_version
  auth_enabled           = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 2
        minutes = 0
      }
    }
  }
}

# Store Redis auth string in Secret Manager
resource "google_secret_manager_secret" "redis_secret" {
  secret_id = "qsr-redis-secret-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "redis_secret_version" {
  secret      = google_secret_manager_secret.redis_secret.id
  secret_data = jsonencode({
    host     = google_redis_instance.redis.host
    port     = google_redis_instance.redis.port
    auth_string = google_redis_instance.redis.auth_string
    url      = "rediss://default:${google_redis_instance.redis.auth_string}@${google_redis_instance.redis.host}:${google_redis_instance.redis.port}"
  })
}
