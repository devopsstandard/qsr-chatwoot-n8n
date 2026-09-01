# Random password generator for Database user
resource "random_password" "db_password" {
  length  = 32
  special = false
}

# Cloud SQL PostgreSQL Instance with Private IP & HA
resource "google_sql_database_instance" "instance" {
  name             = "qsr-sql-${var.instance_name_suffix}-${var.environment}"
  database_version = var.database_version
  region           = var.region
  project          = var.project_id
  encryption_key_name = var.kms_key_id

  depends_on = [var.psa_connection_id]

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = 20
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 14
        retention_unit   = "COUNT"
      }
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
    }
  }

  deletion_protection = var.environment == "prod" ? true : false
}

# Database Creation
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.instance.name
  project  = var.project_id
}

# Database User Creation
resource "google_sql_user" "user" {
  name     = var.database_user
  instance = google_sql_database_instance.instance.name
  password = random_password.db_password.result
  project  = var.project_id
}

# Store database credentials in Secret Manager
resource "google_secret_manager_secret" "db_secret" {
  secret_id = "qsr-sql-secret-${var.instance_name_suffix}-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_secret_version" {
  secret      = google_secret_manager_secret.db_secret.id
  secret_data = jsonencode({
    username = google_sql_user.user.name
    password = random_password.db_password.result
    database = google_sql_database.database.name
    host     = google_sql_database_instance.instance.private_ip_address
    connection_name = google_sql_database_instance.instance.connection_name
  })
}
