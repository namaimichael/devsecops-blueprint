project_id                 = "credible-bank-466613-j6"
region                    = "us-east1"
environment               = "prod"
deployment_context        = "cicd"
terraform_service_account = "github-actions-sa@credible-bank-466613-j6.iam.gserviceaccount.com"
storage_class            = "STANDARD"
allow_force_destroy      = false
created_by               = "github-actions"

lifecycle_rules = [
  {
    age    = 365
    action = "Delete"
  }
]

additional_viewers = []
retention_period_seconds = 7776000
import_if_exists = false
enable_monitoring = true
notification_channels = []