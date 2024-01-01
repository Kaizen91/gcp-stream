terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.gcp_region
  credentials = file("event-stream-409218-65ebaf6386c5.json")
}

# Enabling Service accounts
data "google_compute_default_service_account" "default" {
}

data "google_project" "project" {
}

resource "google_service_account" "sa" {
  account_id   = "cloud-run-pubsub-invoker"
  display_name = "Cloud Run Pub/Sub Invoker"
}

resource "google_project_iam_member" "gce_pub_sub_admin" {
  project = var.project_id
  role    = "roles/pubsub.admin"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_service_account" "data_pipeline_access" {
  project      = var.project_id
  account_id   = "retailpipeline-hyp"
  display_name = "Retail app data pipeline access"
}

# Enabling APIs
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "pubsub" {
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# resource "google_project_service" "cloudrun_api" {
# service = "cloudrun.googleapis.com"
# disable_on_destroy = "false"
# }

# BigQuery Dataset
resource "google_bigquery_dataset" "bq_dataset" {
  dataset_id    = "ecommerce_sink"
  friendly_name = "ecommerce sink"
  description   = "Destination dataset for all pipeline options"
  location      = var.gcp_region

  delete_contents_on_destroy = true

  labels = {
    env = "default"
  }
}

# Pub/Sub Topic
resource "google_pubsub_topic" "ps_topic" {
  name = "hyp-pubsub-topic"

  labels = {
    created = "terraform"
  }

  # depends_on = [google_project_service.pubsub]
}

output "pubsub_topic" {
  value = google_pubsub_topic.ps_topic.name
}

resource "google_cloud_run_service_iam_binding" "binding" {
  location = google_cloud_run_v2_service.default.location
  service  = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  members  = ["serviceAccount:${google_service_account.sa.email}"]
}

resource "google_project_service_identity" "pubsub_agent" {
  provider = google-beta
  project  = data.google_project.project.project_id
  service  = "pubsub.googleapis.com"
}

resource "google_project_iam_binding" "project_token_creator" {
  project = data.google_project.project.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  members = ["serviceAccount:${google_project_service_identity.pubsub_agent.email}"]
}

resource "google_pubsub_subscription" "subscription" {
  name  = "pubsub_subscription"
  topic = google_pubsub_topic.ps_topic.name
  push_config {
    push_endpoint = google_cloud_run_v2_service.default.uri
    oidc_token {
      service_account_email = google_service_account.sa.email
    }
    attributes = {
      x-goog-version = "v1"
    }
  }
  depends_on = [google_cloud_run_v2_service.default]
}

# Cloud Run
resource "google_cloud_run_v2_service" "default" {
  name     = "hyp-run-service-data-processing"
  location = var.gcp_region

  template {
    containers {
      image = "gcr.io/${var.project_id}/pubsub"
    }
  }

  # depends_on = [google_project_service.cloudrun_api]
}

resource "google_bigquery_table" "bq_table_cloud_run" {
  dataset_id          = google_bigquery_dataset.bq_dataset.dataset_id
  table_id            = "cloud_run"
  deletion_protection = false

  labels = {
    env = "default"
  }

  schema = file("bq-table-cloud-run-schema.json")

}
