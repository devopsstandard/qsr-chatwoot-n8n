variable "project_id" {
  type        = string
  description = "GCP Project ID for prod"
  default     = "festive-ally-443007-r4"
}

variable "region" {
  type        = string
  description = "GCP Region"
  default     = "us-central1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository (org/repo)"
  default     = "devopsstandard/qsr-chatwoot-n8n"
}
