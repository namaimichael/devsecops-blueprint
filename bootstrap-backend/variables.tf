variable "project_id" {
  description = "GCP Project ID"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be a valid GCP project ID format."
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "deployment_context" {
  description = "Deployment context (manual, cicd, local)"
  type        = string
  default     = "cicd"
  validation {
    condition     = contains(["manual", "cicd", "local"], var.deployment_context)
    error_message = "Deployment context must be one of: manual, cicd, local."
  }
}

variable "created_by" {
  description = "Who/what created this infrastructure"
  type        = string
  default     = "github-actions"
}

variable "terraform_service_account" {
  description = "Service account email for Terraform operations"
  type        = string
}

variable "additional_viewers" {
  description = "Additional users/service accounts that can view state"
  type        = list(string)
  default     = []
}

variable "storage_class" {
  description = "Storage class for the bucket"
  type        = string
  default     = "STANDARD"
  validation {
    condition = contains([
      "STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"
    ], var.storage_class)
    error_message = "Storage class must be a valid GCS storage class."
  }
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type = list(object({
    age    = number
    action = string
  }))
  default = [
    {
      age    = 90
      action = "Delete"
    }
  ]
}

variable "retention_period_seconds" {
  description = "Retention period in seconds for production buckets"
  type        = number
  default     = 2592000 # 30 days
}

variable "allow_force_destroy" {
  description = "Allow force destroy of bucket (dev only)"
  type        = bool
  default     = false
}

variable "import_if_exists" {
  description = "Check if bucket exists for potential import"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting for state bucket"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}