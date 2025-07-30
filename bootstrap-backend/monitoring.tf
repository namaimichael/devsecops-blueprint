# Alert for unauthorized access to state bucket (only if monitoring is enabled)
resource "google_monitoring_alert_policy" "state_bucket_unauthorized_access" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "Terraform State Bucket - Unauthorized Access"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Unauthorized state bucket access detected"

    condition_threshold {
      # Fixed: Added specific metric type to avoid matching multiple metrics
      filter          = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${google_storage_bucket.tf_state.name}\" AND metric.type=\"storage.googleapis.com/api/request_count\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
        # Added cross_series_reducer for better aggregation
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields     = ["resource.labels.bucket_name"]
      }
    }
  }

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  documentation {
    content = "Unauthorized access detected to Terraform state bucket ${google_storage_bucket.tf_state.name}. Investigate immediately."
  }

  # Notification channels commented out - add specific channels as needed
  # notification_channels = ["projects/PROJECT_ID/notificationChannels/CHANNEL_ID"]
}

# Alternative: More specific alert for failed authentication attempts
resource "google_monitoring_alert_policy" "state_bucket_auth_failures" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "Terraform State Bucket - Authentication Failures"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Authentication failures on state bucket"

    condition_threshold {
      # Monitor authentication failures specifically
      filter          = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${google_storage_bucket.tf_state.name}\" AND metric.type=\"storage.googleapis.com/authz/acl_based_object_access_count\""
      comparison      = "COMPARISON_GT" 
      threshold_value = 5 # Alert after 5 failed attempts
      duration        = "300s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields     = ["resource.labels.bucket_name"]
      }
    }
  }

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  documentation {
    content = "Multiple authentication failures detected on Terraform state bucket ${google_storage_bucket.tf_state.name}. Possible unauthorized access attempt."
  }
}

# Log sink for state bucket access (optional)
resource "google_logging_project_sink" "state_bucket_audit" {
  count       = var.enable_monitoring ? 1 : 0
  name        = "terraform-state-audit-${var.environment}"
  destination = "storage.googleapis.com/${google_storage_bucket.tf_state.name}"

  filter = <<-EOT
    resource.type="gcs_bucket"
    resource.labels.bucket_name="${google_storage_bucket.tf_state.name}"
    protoPayload.methodName=("storage.objects.get" OR "storage.objects.create" OR "storage.objects.delete")
  EOT

  unique_writer_identity = true
}

# Grant the log sink writer access to the bucket (only if log sink is created)
resource "google_storage_bucket_iam_member" "log_sink_writer" {
  count  = var.enable_monitoring ? 1 : 0
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.state_bucket_audit[0].writer_identity
}