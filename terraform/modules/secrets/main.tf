# Secret Manager Resources for Platform Secrets & AgentOps/Slack Integration

resource "google_secret_manager_secret" "agentops_api_key" {
  project   = var.project_id
  secret_id = "agentops-api-key-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "slack_bot_token" {
  project   = var.project_id
  secret_id = "slack-bot-token-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "slack_signing_secret" {
  project   = var.project_id
  secret_id = "slack-signing-secret-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "chatwoot_secret_key_base" {
  project   = var.project_id
  secret_id = "chatwoot-secret-key-base-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "n8n_encryption_key" {
  project   = var.project_id
  secret_id = "n8n-encryption-key-${var.environment}"

  replication {
    auto {}
  }
}
