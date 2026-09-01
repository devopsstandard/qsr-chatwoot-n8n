output "agentops_api_key_secret_id" {
  value       = google_secret_manager_secret.agentops_api_key.secret_id
  description = "Secret ID for AgentOps API Key"
}

output "slack_bot_token_secret_id" {
  value       = google_secret_manager_secret.slack_bot_token.secret_id
  description = "Secret ID for Slack Bot Token"
}

output "slack_signing_secret_id" {
  value       = google_secret_manager_secret.slack_signing_secret.secret_id
  description = "Secret ID for Slack Signing Secret"
}

output "chatwoot_secret_key_base_secret_id" {
  value       = google_secret_manager_secret.chatwoot_secret_key_base.secret_id
  description = "Secret ID for Chatwoot Secret Key Base"
}

output "n8n_encryption_key_secret_id" {
  value       = google_secret_manager_secret.n8n_encryption_key.secret_id
  description = "Secret ID for n8n Encryption Key"
}
