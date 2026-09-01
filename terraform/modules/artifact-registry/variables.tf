variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "location" {
  type        = string
  description = "GCP Location for Artifact Registry"
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "kms_key_id" {
  type        = string
  description = "KMS CryptoKey ID for CMEK encryption"
  default     = null
}
