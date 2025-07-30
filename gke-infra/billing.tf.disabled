# Defines the Google Cloud provider, aliased for billing-related resources
provider "google" {
  alias           = "billing"
  project         = var.project_id
  region          = var.region
  billing_project = var.project_id

  # Set quota project for billing API calls
  user_project_override = true
}

# Enable the Cloud Billing Budget API
resource "google_project_service" "billing_budget_api" {
  provider = google.billing
  project  = var.project_id
  service  = "billingbudgets.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

# The Pub/Sub topic for billing alerts

resource "google_pubsub_topic" "billing_alerts" {
  provider = google.billing
  project  = var.project_id
  name     = "billing-alerts"

  depends_on = [google_project_service.billing_budget_api]
}

# The billing budget resource
resource "google_billing_budget" "free_trial_limit" {
  provider        = google.billing
  billing_account = var.billing_account_id
  display_name    = "DevSecOps Budget Limit"

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "30"
    }
  }

  threshold_rules {
    spend_basis       = "CURRENT_SPEND"
    threshold_percent = 0.5
  }

  threshold_rules {
    spend_basis       = "CURRENT_SPEND"
    threshold_percent = 0.9
  }

  all_updates_rule {
    # Reference the topic created above to ensure correct dependency order
    pubsub_topic                     = google_pubsub_topic.billing_alerts.id
    schema_version                   = "1.0"
    monitoring_notification_channels = []
  }

  depends_on = [
    google_project_service.billing_budget_api,
    google_pubsub_topic.billing_alerts
  ]
}