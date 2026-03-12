resource "google_pubsub_topic" "content_shield_events" {
  name   = "${local.service_name}-events-${var.environment}"
  labels = local.labels

  message_retention_duration = "86400s" # 24 hours

  schema_settings {
    encoding = "JSON"
  }
}

resource "google_pubsub_subscription" "content_shield_events_sub" {
  name  = "${local.service_name}-events-sub-${var.environment}"
  topic = google_pubsub_topic.content_shield_events.id

  labels = local.labels

  ack_deadline_seconds       = 60
  message_retention_duration = "604800s" # 7 days
  retain_acked_messages      = false

  expiration_policy {
    ttl = "" # never expires
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  push_config {
    push_endpoint = google_cloudfunctions2_function.event_collector.url
  }
}
