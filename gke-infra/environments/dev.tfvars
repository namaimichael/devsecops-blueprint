# Production-Ready Development Environment Configuration
project_id = "credible-bank-466613-j6"
region     = "us-west1"
zones      = ["us-west1-a", "us-west1-c"]

# Enhanced node configuration for production workloads
machine_type = "e2-standard-4"  # Upgraded from e2-small to 4 vCPUs, 16GB RAM
node_count   = 2

# Network configuration
network    = "default"
subnetwork = "default"

# Environment settings
environment  = "dev"
cluster_name = "devsecops-gke-salus"

# Billing configuration (preserved from original)
billing_account_id = "016488-1339A3-DA811B"

# Observability settings
enable_monitoring         = true
enable_logging           = true
monitoring_retention_days = 15

# Security settings
enable_workload_identity      = true
enable_network_policy        = true
enable_pod_security_standards = true

# Conditional deployment (disable K8s resources until cluster exists)
deploy_k8s_resources = false