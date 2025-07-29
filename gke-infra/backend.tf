terraform {
  backend "gcs" {
    bucket = "devsecops-tf-state"
    prefix = "gke-infra"    # static prefix only
  }
}
