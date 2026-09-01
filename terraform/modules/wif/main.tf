# Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool-${var.environment}"
  display_name              = "GitHub Actions WIF Pool (${var.environment})"
  description               = "Identity Pool for keyless GitHub Actions OIDC authentication"
  project                   = var.project_id
}

# OIDC Identity Provider for GitHub Actions
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  display_name                        = "GitHub Actions OIDC Provider"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Dedicated Service Account for CI/CD Deployment & Cosign Signing
resource "google_service_account" "cicd_sa" {
  account_id   = "qsr-cicd-sa-${var.environment}"
  display_name = "QSR CI/CD Service Account (${var.environment})"
  project      = var.project_id
}

# IAM Binding allowing GitHub Actions Workload Identity to impersonate the Service Account
resource "google_service_account_iam_member" "wif_sa_user" {
  service_account_id = google_service_account.cicd_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

# Grant CI/CD SA necessary permissions for Artifact Registry, GKE, KMS signing
resource "google_project_iam_member" "ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}

resource "google_project_iam_member" "kms_signer" {
  project = var.project_id
  role    = "roles/cloudkms.signerVerifier"
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}

resource "google_project_iam_member" "gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}
