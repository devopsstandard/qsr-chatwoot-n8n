variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region for Cloud SQL"
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "instance_name_suffix" {
  type        = string
  description = "Suffix identifier for Cloud SQL instance (e.g. chatwoot, n8n)"
}

variable "network_id" {
  type        = string
  description = "VPC Network ID for Private Service Access"
}

variable "psa_connection_id" {
  type        = string
  description = "Dependency reference to Private Service Access connection"
}

variable "database_version" {
  type        = string
  description = "PostgreSQL Database version"
  default     = "POSTGRES_15"
}

variable "tier" {
  type        = string
  description = "Machine tier for Cloud SQL"
  default     = "db-custom-2-7680" # 2 vCPU, 7.5GB RAM
}

variable "availability_type" {
  type        = string
  description = "Availability type: REGIONAL (Multi-AZ HA) or ZONAL"
  default     = "REGIONAL"
}

variable "database_name" {
  type        = string
  description = "Name of initial database to create"
}

variable "database_user" {
  type        = string
  description = "Name of initial database user to create"
}

variable "kms_key_id" {
  type        = string
  description = "Optional KMS CryptoKey ID for CMEK encryption"
  default     = null
}
