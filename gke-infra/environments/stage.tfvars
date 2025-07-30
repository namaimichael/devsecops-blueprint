# Production-Ready Staging Environment Configuration
project_id = "credible-bank-466613-j6"
region     = "us-west1"
zones      = ["us-west1-a", "us-west1-c"]

# Enhanced node configuration for staging workloads
machine_type = "e2-standard-4"  # 4 vCPUs, 16GB RAM
node_count   = 3

# Network configuration
network    = "default"
subnetwork = "default"

# Environment settings
environment  = "stage"
cluster_name = "devsecops-gke-salus-stage"

# Billing configuration
billing_account_id = "016488-1339A3-DA811B"

# Observability settings
enable_monitoring         = true
enable_logging           = true
monitoring_retention_days = 30

# Security settings
enable_workload_identity      = true
enable_network_policy        = true
enable_pod_security_standards = true

# Conditional deployment (disable K8s resources until cluster exists)
deploy_k8s_resources = false