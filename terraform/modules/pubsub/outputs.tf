output "topic_names" {
  description = "All Pub/Sub topic names"
  value = [
    google_pubsub_topic.data_refresh.name,
    google_pubsub_topic.data_quality.name,
    google_pubsub_topic.ml_pipeline.name,
  ]
}

output "data_refresh_topic" {
  description = "Data refresh topic name"
  value       = google_pubsub_topic.data_refresh.name
}

output "data_quality_topic" {
  description = "Data quality topic name"
  value       = google_pubsub_topic.data_quality.name
}

output "ml_pipeline_topic" {
  description = "ML pipeline topic name"
  value       = google_pubsub_topic.ml_pipeline.name
}

output "subscription_names" {
  description = "All Pub/Sub subscription names"
  value = [
    google_pubsub_subscription.data_refresh_sub.name,
    google_pubsub_subscription.data_quality_sub.name,
  ]
}

output "data_refresh_subscription" {
  description = "Data refresh subscription name"
  value       = google_pubsub_subscription.data_refresh_sub.name
}

output "data_quality_subscription" {
  description = "Data quality subscription name"
  value       = google_pubsub_subscription.data_quality_sub.name
}
