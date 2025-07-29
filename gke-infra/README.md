# GKE Infrastructure for DevSecOps Blueprint

This folder contains Terraform code to provision a cost-optimized GKE cluster and billing budget alerts.

## Files

- **main.tf**: GKE cluster and node pool (preemptible, autoscaling) configuration
- **variables.tf**: Input variable definitions
- **outputs.tf**: Outputs (e.g., cluster name)
- **billing.tf**: Billing budget resource to monitor free-trial spend
- **terraform.tfvars**: Sample variable values (replace with your own)

## Prerequisites

- GCP project with Free Trial credits
- Billing Account ID
- `gcloud` authenticated with ADC (`gcloud auth application-default login`)
- Terraform >= 1.0

## Usage

```bash
cd gke-infra
terraform init
terraform apply -var-file="terraform.tfvars"
```