variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources in"
  type        = string
}

variable "zones" {
  description = "A list of GCP zones for node locations"
  type        = list(string)
}

variable "machine_type" {
  description = "The machine type for GKE nodes"
  type        = string
  default     = "e2-small"
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

variable "cluster_name_salus" {
  description = "Name for the salus GKE cluster"
  type        = string
  default     = "devsecops-gke-salus"
}

variable "billing_account_id" {
  description = "The billing account ID used for budget monitoring"
  type        = string
}

variable "node_count" {
  description = "Number of nodes for the Salus cluster"
  type        = number
  default     = 1
}