output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic for content-shield events."
  value       = google_pubsub_topic.content_shield_events.name
}

output "pubsub_topic_id" {
  description = "Fully qualified ID of the Pub/Sub topic."
  value       = google_pubsub_topic.content_shield_events.id
}

output "function_url" {
  description = "HTTPS URL of the event collector Cloud Function."
  value       = google_cloudfunctions2_function.event_collector.url
}

output "dataset_id" {
  description = "BigQuery dataset ID for content-shield data."
  value       = google_bigquery_dataset.content_shield.dataset_id
}

output "events_table_id" {
  description = "Fully qualified BigQuery table ID for raw events."
  value       = "${google_bigquery_dataset.content_shield.dataset_id}.${google_bigquery_table.events.table_id}"
}

output "pain_points_table_id" {
  description = "Fully qualified BigQuery table ID for pain points."
  value       = "${google_bigquery_dataset.content_shield.dataset_id}.${google_bigquery_table.pain_points.table_id}"
}

output "agent_calls_table_id" {
  description = "Fully qualified BigQuery table ID for agent calls."
  value       = "${google_bigquery_dataset.content_shield.dataset_id}.${google_bigquery_table.agent_calls.table_id}"
}
