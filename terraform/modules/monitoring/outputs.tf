output "alert_policy_names" {
  description = "Alert policy names"
  value = [
    google_monitoring_alert_policy.function_failures.display_name,
    # google_monitoring_alert_policy.bigquery_failures.display_name,  # Disabled temporarily
    google_monitoring_alert_policy.function_duration.display_name,
  ]
}

output "notification_channel_id" {
  description = "Notification channel ID (if created)"
  value       = var.notification_email_secret != null ? google_monitoring_notification_channel.email[0].id : null
}

output "function_failures_policy_id" {
  description = "Function failures alert policy ID"
  value       = google_monitoring_alert_policy.function_failures.id
}

# output "bigquery_failures_policy_id" {
#   description = "BigQuery failures alert policy ID"
#   value       = google_monitoring_alert_policy.bigquery_failures.id
# }

output "function_duration_policy_id" {
  description = "Function duration alert policy ID"
  value       = google_monitoring_alert_policy.function_duration.id
}
