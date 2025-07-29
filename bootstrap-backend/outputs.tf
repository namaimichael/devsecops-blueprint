output "backend_bucket" {
  description = "GCS bucket for Terraform remote state"
  value       = google_storage_bucket.tf_state.name
}
