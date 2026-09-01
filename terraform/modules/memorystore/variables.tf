variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "network_id" {
  type        = string
  description = "VPC Network ID"
}

variable "memory_size_gb" {
  type        = number
  description = "Redis memory size in GB"
  default     = 2
}

variable "redis_version" {
  type        = string
  description = "Redis engine version"
  default     = "REDIS_7_0"
}
