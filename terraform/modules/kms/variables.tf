variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "location" {
  type        = string
  description = "KMS KeyRing Location (region or global)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}
