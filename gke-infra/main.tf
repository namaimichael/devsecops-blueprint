
// GKE Cluster - Enhanced for Production with Security Best Practices
resource "google_container_cluster" "gke_cluster_salus" {
  name                     = "devsecops-gke-salus"
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = var.node_count
  node_locations           = var.zones
  deletion_protection      = false

  network    = var.network
  subnetwork = var.subnetwork

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    network_policy_config {
      disabled = false
    }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "69.166.236.89/32" // Replace with your specific allowed IP range
      display_name = "My Public IP"
    }
  }

  # network_config {
  #   enable_intra_node_visibility = true
  # }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 100
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 2
      maximum       = 200
    }
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Production Node Pool: For observability and applications - FIXED
resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-node-pool"
  cluster  = google_container_cluster.gke_cluster_salus.name
  location = var.region

  # Enhanced autoscaling for production workloads
  autoscaling {
    min_node_count  = 2  # Always have 2 nodes minimum
    max_node_count  = 10 # Allow scaling up to 10 nodes
    location_policy = "BALANCED"
  }

  node_config {
    # Production-grade machine type with sufficient resources
    machine_type = "e2-standard-4" # 4 vCPUs, 16GB RAM
    disk_size_gb = 50              # Increased disk for observability data
    disk_type    = "pd-ssd"        # SSD for better performance

    # FIXED: Use only spot instances, not preemptible
    spot = true # Use spot instances for cost savings

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      environment = "production-ready"
      node-type   = "observability-capable"
    }

    # Enhanced security
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Resource reservations for system processes
    linux_node_config {
      sysctls = {
        "net.core.rmem_max" = "134217728"
        "net.core.wmem_max" = "134217728"
      }
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = 1
    max_unavailable = 0
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Optional: Dedicated System Node Pool (for critical system components) 
resource "google_container_node_pool" "system_nodes" {
  name     = "system-node-pool"
  cluster  = google_container_cluster.gke_cluster_salus.name
  location = var.region

  # System pool - always available, no spot instances
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    machine_type = "e2-medium" # 1 vCPU, 4GB RAM - sufficient for system workloads
    disk_size_gb = 30
    disk_type    = "pd-standard"


    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      environment = "production-ready"
      node-type   = "system"
    }

    # Taint for system workloads only
    taint {
      key    = "node-type"
      value  = "system"
      effect = "NO_SCHEDULE"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Install Argo CD via Helm - Enhanced for Production
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.2.2"

  # Enhanced values for production
  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
        # Resource limits for production
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
        # High availability
        replicas = 2
        config = {
          "server.insecure" = true
        }
      }

      controller = {
        replicas = 1
        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }
      }

      repoServer = {
        replicas = 2
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      applicationSet = {
        enabled = true
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
    })
  ]

  depends_on = [google_container_node_pool.primary_nodes]
}

// ────────────────────────────────────────────────────────────────────────────
// Argo CD "app-of-apps" root Application
resource "kubernetes_manifest" "argocd_root_app" {
  depends_on = [
    helm_release.argocd
  ]
  manifest = yamldecode(file("${path.module}/manifests/bootstrap/argocd-root-app.yaml"))
}

// Argo CD Image Updater - Enhanced
resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = false
  version          = "0.12.3"

  values = [
    yamlencode({
      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    })
  ]

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