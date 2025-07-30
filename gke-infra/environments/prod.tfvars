# Production-Ready Production Environment Configuration
project_id = "credible-bank-466613-j6"
region     = "us-east1"
zones      = ["us-east1-a", "us-east1-c"]

# Enhanced node configuration for production workloads
machine_type = "e2-standard-8"  # 8 vCPUs, 32GB RAM for production
node_count   = 5

# Network configuration
network    = "default"
subnetwork = "default"

# Environment settings
environment  = "prod"
cluster_name = "devsecops-gke-salus-prod"

# Billing configuration
billing_account_id = "016488-1339A3-DA811B"

# Observability settings
enable_monitoring         = true
enable_logging           = true
monitoring_retention_days = 90

# Security settings
enable_workload_identity      = true
enable_network_policy        = true
enable_pod_security_standards = true

# Conditional deployment (disable K8s resources until cluster exists)
deploy_k8s_resources = false