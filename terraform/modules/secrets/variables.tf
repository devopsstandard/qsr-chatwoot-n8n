variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev or prod)"
}

variable "kms_key_id" {
  type        = string
  description = "KMS CMEK Key ID for secret encryption"
  default     = null
}
