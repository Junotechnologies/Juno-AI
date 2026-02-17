output "bronze_dataset_id" {
  description = "Bronze dataset ID"
  value       = google_bigquery_dataset.bronze.dataset_id
}

output "silver_dataset_id" {
  description = "Silver dataset ID"
  value       = google_bigquery_dataset.silver.dataset_id
}

output "gold_dataset_id" {
  description = "Gold dataset ID"
  value       = google_bigquery_dataset.gold.dataset_id
}

output "quality_dataset_id" {
  description = "Quality dataset ID"
  value       = google_bigquery_dataset.quality.dataset_id
}

output "bronze_dataset_name" {
  description = "Bronze dataset full name"
  value       = google_bigquery_dataset.bronze.friendly_name
}

output "silver_dataset_name" {
  description = "Silver dataset full name"
  value       = google_bigquery_dataset.silver.friendly_name
}

output "gold_dataset_name" {
  description = "Gold dataset full name"
  value       = google_bigquery_dataset.gold.friendly_name
}

output "quality_dataset_name" {
  description = "Quality dataset full name"
  value       = google_bigquery_dataset.quality.friendly_name
}

output "all_dataset_ids" {
  description = "Map of all dataset IDs"
  value = {
    bronze  = google_bigquery_dataset.bronze.dataset_id
    silver  = google_bigquery_dataset.silver.dataset_id
    gold    = google_bigquery_dataset.gold.dataset_id
    quality = google_bigquery_dataset.quality.dataset_id
  }
}
