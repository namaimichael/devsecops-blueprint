// ────────────────────────────────────────────────────────────────────────────
// GKE Cluster
resource "google_container_cluster" "gke_cluster_salus" {
  name                     = "devsecops-gke-salus"
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = var.node_count
  node_locations           = var.zones
  deletion_protection      = false

  network    = var.network
  subnetwork = var.subnetwork

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

// ────────────────────────────────────────────────────────────────────────────
// GKE Node Pool: primary (stateless, preemptible)
resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-node-pool"
  cluster  = google_container_cluster.gke_cluster_salus.name
  location = var.region

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 20
    preemptible  = true
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      environment = "dev"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

// Install Argo CD via Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.2.2"

  set = [
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "controller.replicaCount"
      value = "1"
    },
    {
      name  = "configs.params.server\\.insecure"
      value = "true"
    },
  ]
}

// ────────────────────────────────────────────────────────────────────────────
// Argo CD "app-of-apps" root Application
resource "kubernetes_manifest" "argocd_root_app" {
  depends_on = [
    helm_release.argocd
  ]
  manifest = yamldecode(file("${path.module}/manifests/bootstrap/argocd-root-app.yaml"))
}

// Argo CD Image Updater
resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = false
  version          = "0.12.3"

  # no chart values needed for default behavior
  depends_on = [helm_release.argocd]
}

// ────────────────────────────────────────────────────────────────────────────
// FastAPI child Application
resource "kubernetes_manifest" "fastapi_app" {
  depends_on = [
    kubernetes_manifest.argocd_root_app
  ]
  manifest = yamldecode(file("${path.module}/manifests/apps/fastapi-app.yaml"))
}