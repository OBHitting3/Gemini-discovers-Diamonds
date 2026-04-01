resource "google_storage_bucket" "gcf_source" {
  name                        = "${var.project_id}-${local.service_name}-gcf-source"
  location                    = var.region
  uniform_bucket_level_access = true
  labels                      = local.labels

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_object" "gcf_source_archive" {
  name   = "event-collector-${filemd5("${path.module}/../../src/content_shield/collector.py")}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = "${path.module}/../../dist/event_collector.zip"
}

resource "google_service_account" "event_collector" {
  account_id   = "${local.service_name}-collector"
  display_name = "Content Shield Event Collector"
  description  = "Service account for the content-shield event collector Cloud Function."
}

resource "google_project_iam_member" "collector_bq_writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.event_collector.email}"
}

resource "google_cloudfunctions2_function" "event_collector" {
  name     = "${local.service_name}-event-collector-${var.environment}"
  location = var.region
  labels   = local.labels

  build_config {
    runtime     = "python312"
    entry_point = "handle_event"

    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source.name
        object = google_storage_bucket_object.gcf_source_archive.name
      }
    }
  }

  service_config {
    max_instance_count    = 10
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 120
    service_account_email = google_service_account.event_collector.email

    environment_variables = {
      PROJECT_ID  = var.project_id
      DATASET_ID  = google_bigquery_dataset.content_shield.dataset_id
      ENVIRONMENT = var.environment
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.content_shield_events.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}
