<file name=0 path=/Users/user/projects/devsecop/devsecops-blueprint/README.md><details>
<summary>Click to Expand MermaidJS</summary>
```mermaid
graph TD
    A[Developer Commit] --> B[GitHub Actions CI/CD]
    B --> C[Static Code Analysis (SonarQube)]
    B --> D[Dependency Scan (OWASP)]
    B --> E[Container Scan (Trivy)]
    B --> F[Build & Push Docker Image]
    F --> G[GitOps Repo (Argo CD / Flux)]
    G --> H[Kubernetes Cluster (Minikube)]
    H --> I[Mock App Deployment]

    subgraph Observability Stack
        H --> J[Prometheus Metrics]
        H --> K[Loki Logs]
        H --> L[Jaeger Traces]
        J --> M[Grafana Dashboards]
        K --> M
        L --> M
    end

    M --> N[Alerts / Incident Response]
```
</details>

![DevSecOps Architecture Diagram](docs/architecture-diagram.png)

> ✅ This image should now render correctly. If it doesn't:
> - Ensure the file exists at `devsecops-blueprint/docs/architecture-diagram.png`
> - Run `git add docs/architecture-diagram.png && git commit -m "Add diagram"`
> - GitHub might need a few seconds to reflect image updates.
</file>
