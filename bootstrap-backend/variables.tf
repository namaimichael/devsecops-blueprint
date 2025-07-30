variable "project_id" {
  description = "GCP project to host the backend bucket"
  type        = string
}

variable "location" {
  description = "GCS bucket location (multi-regional or regional)"
  type        = string
  default     = "US"
}

variable "bucket_name" {
  description = "Name for the Terraform state bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
}
