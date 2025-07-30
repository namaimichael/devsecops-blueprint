# Enhanced variables for production-ready infrastructure
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "us-west1"
}

variable "zones" {
  description = "A list of GCP zones for node locations"
  type        = list(string)
  default     = ["us-west1-a", "us-west1-c"]
}

variable "machine_type" {
  description = "The machine type for GKE nodes (enhanced for production)"
  type        = string
  default     = "e2-standard-4" # Upgraded from e2-small to 4 vCPUs, 16GB RAM
}

variable "network" {
  description = "The VPC network to use"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to use"
  type        = string
  default     = "default"
}

# Standardized cluster name variable (renamed from cluster_name_salus)
variable "cluster_name" {
  description = "Name for the GKE cluster"
  type        = string
  default     = "devsecops-gke-salus"
}

# Preserved for backward compatibility (if needed elsewhere)
variable "cluster_name_salus" {
  description = "Name for the salus GKE cluster (deprecated - use cluster_name)"
  type        = string
  default     = "devsecops-gke-salus"
}

variable "billing_account_id" {
  description = "The billing account ID used for budget monitoring"
  type        = string
}

variable "node_count" {
  description = "Initial number of nodes for the cluster"
  type        = number
  default     = 2 # Increased from 1 to 2 for production readiness
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Observability configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack"
  type        = bool
  default     = true
}

variable "monitoring_retention_days" {
  description = "Days to retain monitoring data"
  type        = number
  default     = 15
}

# Security configuration
variable "enable_workload_identity" {
  description = "Enable Workload Identity"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable Network Policy"
  type        = bool
  default     = true
}

variable "enable_pod_security_standards" {
  description = "Enable Pod Security Standards"
  type        = bool
  default     = true
}

variable "deploy_k8s_resources" {
  description = "Whether to deploy Kubernetes resources (namespaces, helm charts, etc.)"
  type        = bool
  default     = false
}
variable "billing_account_id" {
  description = "The billing account ID to associate with the project"
  type        = string
  default     = ""
}