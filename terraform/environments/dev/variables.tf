variable "project_id" {
  type        = string
  description = "GCP Project ID for dev"
}

variable "region" {
  type        = string
  description = "GCP Region"
  default     = "us-central1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository (org/repo)"
}
