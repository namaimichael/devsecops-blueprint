terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.location
}

# Import existing bucket if it exists
import {
  to = google_storage_bucket.tf_state
  id = var.bucket_name
}

resource "google_storage_bucket" "tf_state" {
  name                        = var.bucket_name
  location                    = var.location
  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    owner = "devsecops-blueprint"
    env   = var.environment
  }

  # Prevent destruction of state bucket
  lifecycle {
    prevent_destroy = true
  }
}