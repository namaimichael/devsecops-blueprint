---

### `gke-infra/README.md`

```markdown
# GKE Infrastructure

Terraform code to provision a cost-optimized GKE cluster, node pools, and core add-ons (ArgoCD, observability stack).

---

## Purpose
- Deploy a GKE cluster in `us-central1` with auto-scaling and spot/preemptible node pools  
- Install ArgoCD for GitOps and the Prometheus/Grafana/Loki observability stack  
- Configure billing alerts via Pub/Sub and Budget

## Prerequisites
- Google Cloud SDK authenticated (`gcloud auth application-default login`)  
- `kubectl` and `helm` CLI tools installed  
- Terraform ≥ 1.0  
- A GCS bucket for remote state created by `bootstrap-backend/`  
- Service account or user with `roles/container.admin` and `roles/compute.admin`

## Usage
1. Initialize Terraform with remote backend:
    ```bash
    cd gke-infra
    terraform init
    ```
2. Apply for **development** environment:
    ```bash
    terraform apply -var-file=environments/dev.tfvars
    ```
3. Confirm resources:
    ```bash
    gcloud container clusters list --region us-central1
    kubectl get nodes
    ```
4. Port-forward Grafana:
    ```bash
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
    # Access at http://localhost:3000 (credentials: admin/devsecops-demo)
    ```

## Next Steps
- Deploy your application via ArgoCD (see `manifests/`)  
- Implement security hardening in `gke-infra/security.tf`  
- Tune autoscaling, HPA/VPA, and resource quotas