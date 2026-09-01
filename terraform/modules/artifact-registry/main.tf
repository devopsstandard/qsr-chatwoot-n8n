resource "google_artifact_registry_repository" "repo" {
  location      = var.location
  repository_id = "qsr-containers-${var.environment}"
  description   = "Secure Docker container repository for QSR Chatwoot & n8n microservices"
  format        = "DOCKER"
  kms_key_name  = var.kms_key_id
  project       = var.project_id

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state = "UNTAGGED"
    }
  }
}
