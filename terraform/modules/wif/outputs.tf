output "provider_name" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "Full provider resource name for GitHub Actions workflow configuration"
}

output "service_account_email" {
  value       = google_service_account.cicd_sa.email
  description = "Service Account email impersonated by GitHub Actions"
}
