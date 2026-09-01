output "repository_id" {
  value       = google_artifact_registry_repository.repo.repository_id
  description = "The ID of the Artifact Registry Repository"
}

output "repository_url" {
  value       = "${var.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
  description = "Full URL of the Docker repository"
}
