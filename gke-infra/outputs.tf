# GKE cluster name
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.gke_cluster_salus.name
}

# GKE cluster region
output "gke_cluster_region" {
  description = "Region of the GKE cluster"
  value       = google_container_cluster.gke_cluster_salus.location
}

# Project ID
output "project_id" {
  description = "The project ID"
  value       = var.project_id
}

# GKE cluster endpoint
output "gke_cluster_endpoint" {
  description = "Endpoint for GKE cluster"
  value       = google_container_cluster.gke_cluster_salus.endpoint
  sensitive   = true
}

# GKE cluster CA certificate
output "gke_cluster_ca_certificate" {
  description = "CA certificate for GKE cluster"
  value       = google_container_cluster.gke_cluster_salus.master_auth[0].cluster_ca_certificate
  sensitive   = true
}