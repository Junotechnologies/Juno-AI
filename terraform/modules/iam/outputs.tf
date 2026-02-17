output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.cloud_functions_sa.email
}

output "service_account_name" {
  description = "Service account name"
  value       = google_service_account.cloud_functions_sa.name
}

output "service_account_id" {
  description = "Service account unique ID"
  value       = google_service_account.cloud_functions_sa.unique_id
}

output "service_account_member" {
  description = "Service account as a member string"
  value       = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
}
