# Alert for unauthorized access to state bucket (only if monitoring is enabled)
resource "google_monitoring_alert_policy" "state_bucket_unauthorized_access" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "Terraform State Bucket - Unauthorized Access"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Unauthorized state bucket access detected"

    condition_threshold {
      filter          = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${google_storage_bucket.tf_state.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
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
