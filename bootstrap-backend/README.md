# Bootstrap Backend

Provisions the GCS bucket to store Terraform remote state.

---

## Purpose
- Create and configure a Google Cloud Storage bucket for remote Terraform state  
- Enable versioning and lifecycle rules for clean state management

## Prerequisites
- Google Cloud SDK installed and authenticated (`gcloud auth application-default login`)  
- A GCP project with Billing enabled  
- IAM permission: `roles/storage.admin` on the target project

## Usage
1. Initialize Terraform:
    ```bash
    cd bootstrap-backend
    terraform init
    ```
2. Apply configuration:
    ```bash
    terraform apply \
      -var="project_id=<GCP_PROJECT_ID>" \
      -var="location=<BUCKET_LOCATION>" \
      -var="bucket_name=<STATE_BUCKET_NAME>"
    ```
3. Verify bucket creation:
    ```bash
    gsutil ls -L gs://<STATE_BUCKET_NAME>
    ```

## Next Steps
- Copy the bucket name into `gke-infra/backend.tf` under:
  ```hcl
  backend "gcs" {
    bucket = "<STATE_BUCKET_NAME>"
  }