# Create Slack notification channel
resource "google_monitoring_notification_channel" "slack_alerts" {
  count        = var.enable_monitoring && var.slack_webhook_url != "" ? 1 : 0
  display_name = "Slack Security Alerts"
  type         = "slack"
  
  labels = {
    channel_name = "#security-alerts"  # Update with your channel name
    url          = var.slack_webhook_url
  }

  enabled = true
}

# Create email notification channel (backup)
resource "google_monitoring_notification_channel" "email_alerts" {
  count        = var.enable_monitoring && var.notification_email != "" ? 1 : 0
  display_name = "Email Security Alerts"
  type         = "email"
  
  labels = {
    email_address = var.notification_email
  }

  enabled = true
}

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
    content = "🚨 SECURITY ALERT: Unauthorized access detected to Terraform state bucket ${google_storage_bucket.tf_state.name}. Investigate immediately.\n\nBucket: ${google_storage_bucket.tf_state.name}\nEnvironment: ${var.environment}\nProject: ${var.project_id}"
  }

  # Add notification channels
  notification_channels = compact([
    length(google_monitoring_notification_channel.slack_alerts) > 0 ? google_monitoring_notification_channel.slack_alerts[0].id : null,
    length(google_monitoring_notification_channel.email_alerts) > 0 ? google_monitoring_notification_channel.email_alerts[0].id : null
  ])
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
    content = "🔐 AUTH FAILURE ALERT: Multiple authentication failures detected on Terraform state bucket ${google_storage_bucket.tf_state.name}. Possible unauthorized access attempt.\n\nBucket: ${google_storage_bucket.tf_state.name}\nEnvironment: ${var.environment}\nThreshold: 5 failed attempts\nInvestigate source IPs and access patterns immediately."
  }

  # Add notification channels  
  notification_channels = compact([
    length(google_monitoring_notification_channel.slack_alerts) > 0 ? google_monitoring_notification_channel.slack_alerts[0].id : null,
    length(google_monitoring_notification_channel.email_alerts) > 0 ? google_monitoring_notification_channel.email_alerts[0].id : null
  ])
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