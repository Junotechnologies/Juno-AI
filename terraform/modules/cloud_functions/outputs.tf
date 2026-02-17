output "refresh_silver_name" {
  description = "Refresh silver function name"
  value       = google_cloudfunctions2_function.refresh_silver.name
}

output "refresh_silver_url" {
  description = "Refresh silver function URL"
  value       = google_cloudfunctions2_function.refresh_silver.service_config[0].uri
}

output "refresh_gold_name" {
  description = "Refresh gold function name"
  value       = google_cloudfunctions2_function.refresh_gold.name
}

output "refresh_gold_url" {
  description = "Refresh gold function URL"
  value       = google_cloudfunctions2_function.refresh_gold.service_config[0].uri
}

output "quality_check_name" {
  description = "Quality check function name"
  value       = var.enable_quality_checks ? google_cloudfunctions2_function.quality_check[0].name : null
}

output "quality_check_url" {
  description = "Quality check function URL"
  value       = var.enable_quality_checks ? google_cloudfunctions2_function.quality_check[0].service_config[0].uri : null
}

output "ml_snapshot_name" {
  description = "ML snapshot function name"
  value       = var.enable_ml_snapshots ? google_cloudfunctions2_function.ml_snapshot[0].name : null
}

output "ml_snapshot_url" {
  description = "ML snapshot function URL"
  value       = var.enable_ml_snapshots ? google_cloudfunctions2_function.ml_snapshot[0].service_config[0].uri : null
}

output "function_names" {
  description = "All deployed function names"
  value = compact([
    google_cloudfunctions2_function.refresh_silver.name,
    google_cloudfunctions2_function.refresh_gold.name,
    var.enable_quality_checks ? google_cloudfunctions2_function.quality_check[0].name : null,
    var.enable_ml_snapshots ? google_cloudfunctions2_function.ml_snapshot[0].name : null,
  ])
}

output "function_urls" {
  description = "All deployed function URLs"
  value = {
    refresh_silver = google_cloudfunctions2_function.refresh_silver.service_config[0].uri
    refresh_gold   = google_cloudfunctions2_function.refresh_gold.service_config[0].uri
    quality_check  = var.enable_quality_checks ? google_cloudfunctions2_function.quality_check[0].service_config[0].uri : null
    ml_snapshot    = var.enable_ml_snapshots ? google_cloudfunctions2_function.ml_snapshot[0].service_config[0].uri : null
  }
}
