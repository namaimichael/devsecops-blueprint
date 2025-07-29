# DevSecOps Blueprint: GKE on GCP  

## **Architecture**  
- **Infra**: Terraform-provisioned GKE (preemptible nodes), GCS remote state.  
- **CI/CD**: GitHub Actions → Trivy/Semgrep → GHCR → ArgoCD (GitOps).  
- **Observability**: Prometheus/Grafana/Loki, SLI/SLO alerts.  

## **Quickstart**  
```bash
terraform -chdir=gke-infra init  
terraform -chdir=gke-infra apply  
kubectl apply -f manifests/  