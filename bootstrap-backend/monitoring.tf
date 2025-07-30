resource "google_monitoring_alert_policy" "state_bucket_access" {
  display_name = "Terraform State Bucket Unauthorized Access"
  combiner     = "OR"
  
  conditions {
    display_name = "Unauthorized state access"
    
    condition_threshold {
      filter         = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${google_storage_bucket.tf_state.name}\""
      comparison     = "COMPARISON_GT"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.notification_channels
}