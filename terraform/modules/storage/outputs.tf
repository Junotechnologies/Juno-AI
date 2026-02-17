output "functions_bucket_name" {
  description = "Functions source bucket name"
  value       = google_storage_bucket.functions_source.name
}

output "functions_bucket_url" {
  description = "Functions source bucket URL"
  value       = google_storage_bucket.functions_source.url
}

output "staging_bucket_name" {
  description = "Staging bucket name"
  value       = google_storage_bucket.staging.name
}

output "staging_bucket_url" {
  description = "Staging bucket URL"
  value       = google_storage_bucket.staging.url
}

output "ml_artifacts_bucket_name" {
  description = "ML artifacts bucket name"
  value       = google_storage_bucket.ml_artifacts.name
}

output "ml_artifacts_bucket_url" {
  description = "ML artifacts bucket URL"
  value       = google_storage_bucket.ml_artifacts.url
}

output "all_bucket_names" {
  description = "All bucket names"
  value = {
    functions_source = google_storage_bucket.functions_source.name
    staging          = google_storage_bucket.staging.name
    ml_artifacts     = google_storage_bucket.ml_artifacts.name
  }
}
