resource "google_bigquery_dataset" "content_shield" {
  dataset_id    = "content_shield_${var.environment}"
  friendly_name = "Content Shield (${var.environment})"
  description   = "Dataset for content-shield event data and analytics."
  location      = var.region
  labels        = local.labels

  default_table_expiration_ms     = null
  default_partition_expiration_ms = null

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "WRITER"
    user_by_email = google_service_account.event_collector.email
  }
}

resource "google_bigquery_table" "events" {
  dataset_id          = google_bigquery_dataset.content_shield.dataset_id
  table_id            = "events"
  description         = "Raw content-shield events ingested from Pub/Sub."
  deletion_protection = var.environment == "prod"
  labels              = local.labels

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  clustering = ["event_type", "source"]

  schema = jsonencode([
    {
      name        = "event_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique event identifier."
    },
    {
      name        = "timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Time the event was emitted."
    },
    {
      name        = "event_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Type of content-shield event."
    },
    {
      name        = "source"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Originating service or component."
    },
    {
      name        = "payload"
      type        = "JSON"
      mode        = "NULLABLE"
      description = "Event payload as JSON."
    },
    {
      name        = "severity"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Event severity level."
    }
  ])
}

resource "google_bigquery_table" "pain_points" {
  dataset_id          = google_bigquery_dataset.content_shield.dataset_id
  table_id            = "pain_points"
  description         = "Detected content pain points aggregated over time."
  deletion_protection = var.environment == "prod"
  labels              = local.labels

  time_partitioning {
    type  = "DAY"
    field = "detected_at"
  }

  clustering = ["category", "severity"]

  schema = jsonencode([
    {
      name        = "pain_point_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique pain-point identifier."
    },
    {
      name        = "detected_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "When the pain point was first detected."
    },
    {
      name        = "category"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Pain-point category (e.g. readability, accuracy, staleness)."
    },
    {
      name        = "severity"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Pain-point severity (low, medium, high, critical)."
    },
    {
      name        = "description"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Human-readable description of the pain point."
    },
    {
      name        = "content_url"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "URL of the affected content."
    },
    {
      name        = "score"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Numeric pain-point score (0.0 to 1.0)."
    },
    {
      name        = "resolved"
      type        = "BOOLEAN"
      mode        = "REQUIRED"
      description = "Whether the pain point has been resolved."
    }
  ])
}

resource "google_bigquery_table" "agent_calls" {
  dataset_id          = google_bigquery_dataset.content_shield.dataset_id
  table_id            = "agent_calls"
  description         = "Log of agent invocations and their outcomes."
  deletion_protection = var.environment == "prod"
  labels              = local.labels

  time_partitioning {
    type  = "DAY"
    field = "called_at"
  }

  clustering = ["agent_name", "status"]

  schema = jsonencode([
    {
      name        = "call_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique agent-call identifier."
    },
    {
      name        = "called_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "When the agent was invoked."
    },
    {
      name        = "agent_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Name of the agent that was called."
    },
    {
      name        = "status"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Call outcome status (success, failure, timeout)."
    },
    {
      name        = "duration_ms"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Agent call duration in milliseconds."
    },
    {
      name        = "input_tokens"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Number of input tokens consumed."
    },
    {
      name        = "output_tokens"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Number of output tokens produced."
    },
    {
      name        = "pain_point_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Associated pain-point ID, if applicable."
    },
    {
      name        = "error_message"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Error message if the call failed."
    }
  ])
}
