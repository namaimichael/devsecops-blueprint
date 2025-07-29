terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0, < 7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.15, < 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8, < 4.0"
    }
  }
}

# ——————————————————————————————————————————————————————————————————————————
# Primary GCP provider (infra resources + billing API)
provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

# ——————————————————————————————————————————————————————————————————————————
# Fetch Application Default Credentials
data "google_client_config" "default" {}

# ——————————————————————————————————————————————————————————————————————————
# Read GKE cluster to configure K8s/Helm providers
data "google_container_cluster" "primary" {
  name     = google_container_cluster.gke_cluster_salus.name
  location = var.region
}

# ——————————————————————————————————————————————————————————————————————————
# Kubernetes provider wired to your GKE cluster
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# ——————————————————————————————————————————————————————————————————————————
# Helm provider pointed at the same cluster
provider "helm" {
  kubernetes = {
    host                   = "https://${data.google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}