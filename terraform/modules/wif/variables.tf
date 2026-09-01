variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository string (e.g. org/qsr-platform-infra)"
}
