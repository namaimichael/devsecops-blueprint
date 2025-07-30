project_id                 = "credible-bank-466613-j6"
region                    = "us-west1"
environment               = "stage"
deployment_context        = "cicd"
terraform_service_account = "github-actions-sa@credible-bank-466613-j6.iam.gserviceaccount.com"
storage_class            = "STANDARD"
allow_force_destroy      = false
created_by               = "github-actions"

lifecycle_rules = [
  {
    age    = 60
    action = "Delete"
  }
]
additional_viewers = []
retention_period_seconds = 2592000
import_if_exists = false
enable_monitoring = true
notification_channels = []