terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  # Generate unique bucket name based on project, environment, and deployment context
  bucket_name = "${var.project_id}-tfstate-${var.environment}-${var.deployment_context}"
  
  # Labels for resource management
  common_labels = {
    managed_by    = "terraform"
    project       = "devsecops-blueprint"
    environment   = var.environment
    context       = var.deployment_context
    created_by    = var.created_by
  }
}

resource "google_storage_bucket" "tf_state" {
  name                        = local.bucket_name
  location                    = var.region
  storage_class              = var.storage_class
  force_destroy              = var.environment == "dev" ? var.allow_force_destroy : false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Lifecycle management based on environment
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      condition {
        age = lifecycle_rule.value.age
      }
      action {
        type = lifecycle_rule.value.action
      }
    }
  }

  # Object retention for production
  dynamic "retention_policy" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      retention_period = var.retention_period_seconds
    }
  }

  labels = local.common_labels

  # Static lifecycle block - cannot use variables
  lifecycle {
    prevent_destroy = false  # Set to true manually for production buckets
  }
}

# IAM for state bucket
resource "google_storage_bucket_iam_member" "tf_state_admin" {
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.terraform_service_account}"
}

resource "google_storage_bucket_iam_member" "tf_state_viewer" {
  for_each = toset(var.additional_viewers)
  bucket   = google_storage_bucket.tf_state.name
  role     = "roles/storage.objectViewer"
  member   = each.value
}