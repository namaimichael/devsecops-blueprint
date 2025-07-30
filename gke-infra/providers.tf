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
# Kubernetes provider wired to your GKE cluster
# Uses the cluster resource directly instead of data source to avoid dependency issues
provider "kubernetes" {
  host                   = "https://${google_container_cluster.gke_cluster_salus.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke_cluster_salus.master_auth[0].cluster_ca_certificate)

  # Ignore cluster resource changes during apply
  ignore_annotations = [
    "^autopilot\\.gke\\.io\\/.*",
    "^cloud\\.google\\.com\\/.*"
  ]
}

# ——————————————————————————————————————————————————————————————————————————
# Helm provider pointed at the same cluster
provider "helm" {
  kubernetes = {
    host                   = "https://${google_container_cluster.gke_cluster_salus.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.gke_cluster_salus.master_auth[0].cluster_ca_certificate)
  }

  # Ignore cluster resource changes during apply
  registry {
    url      = "oci://registry-1.docker.io"
    username = ""
    password = ""
  }
}