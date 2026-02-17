output "scheduler_job_names" {
  description = "All scheduler job names"
  value = compact([
    google_cloud_scheduler_job.refresh_silver.name,
    google_cloud_scheduler_job.refresh_gold.name,
    var.enable_quality_checks && length(google_cloud_scheduler_job.quality_check) > 0 ? google_cloud_scheduler_job.quality_check[0].name : "",
    var.enable_ml_snapshots && length(google_cloud_scheduler_job.ml_snapshot) > 0 ? google_cloud_scheduler_job.ml_snapshot[0].name : "",
  ])
}

output "refresh_silver_job_name" {
  description = "Refresh silver scheduler job name"
  value       = google_cloud_scheduler_job.refresh_silver.name
}

output "refresh_gold_job_name" {
  description = "Refresh gold scheduler job name"
  value       = google_cloud_scheduler_job.refresh_gold.name
}

output "quality_check_job_name" {
  description = "Quality check scheduler job name"
  value       = var.enable_quality_checks && length(google_cloud_scheduler_job.quality_check) > 0 ? google_cloud_scheduler_job.quality_check[0].name : ""
}

output "ml_snapshot_job_name" {
  description = "ML snapshot scheduler job name"
  value       = var.enable_ml_snapshots && length(google_cloud_scheduler_job.ml_snapshot) > 0 ? google_cloud_scheduler_job.ml_snapshot[0].name : ""
}
