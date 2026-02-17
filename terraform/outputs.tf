# ========================================
# PROJECT OUTPUTS
# ========================================

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "GCP region"
  value       = var.region
}

# ========================================
# IAM OUTPUTS
# ========================================

output "service_account_email" {
  description = "Service account email for Cloud Functions"
  value       = module.iam.service_account_email
}

output "service_account_name" {
  description = "Service account name"
  value       = module.iam.service_account_name
}

# ========================================
# BIGQUERY OUTPUTS
# ========================================

output "bronze_dataset_id" {
  description = "Bronze layer dataset ID"
  value       = module.bigquery.bronze_dataset_id
}

output "silver_dataset_id" {
  description = "Silver layer dataset ID"
  value       = module.bigquery.silver_dataset_id
}

output "gold_dataset_id" {
  description = "Gold layer dataset ID"
  value       = module.bigquery.gold_dataset_id
}

output "quality_dataset_id" {
  description = "Quality layer dataset ID"
  value       = module.bigquery.quality_dataset_id
}

output "bigquery_datasets" {
  description = "All BigQuery dataset IDs"
  value = {
    bronze  = module.bigquery.bronze_dataset_id
    silver  = module.bigquery.silver_dataset_id
    gold    = module.bigquery.gold_dataset_id
    quality = module.bigquery.quality_dataset_id
  }
}

# ========================================
# STORAGE OUTPUTS
# ========================================

output "functions_bucket_name" {
  description = "Cloud Functions source code bucket"
  value       = module.storage.functions_bucket_name
}

output "staging_bucket_name" {
  description = "Staging/temporary files bucket"
  value       = module.storage.staging_bucket_name
}

# ========================================
# CLOUD FUNCTIONS OUTPUTS
# ========================================

output "cloud_functions" {
  description = "Deployed Cloud Functions information"
  value = {
    refresh_silver = {
      name = module.cloud_functions.refresh_silver_name
      url  = module.cloud_functions.refresh_silver_url
    }
    refresh_gold = {
      name = module.cloud_functions.refresh_gold_name
      url  = module.cloud_functions.refresh_gold_url
    }
    quality_check = var.enable_quality_checks ? {
      name = module.cloud_functions.quality_check_name
      url  = module.cloud_functions.quality_check_url
    } : null
    ml_snapshot = var.enable_ml_snapshots ? {
      name = module.cloud_functions.ml_snapshot_name
      url  = module.cloud_functions.ml_snapshot_url
    } : null
  }
}

# ========================================
# SCHEDULER OUTPUTS
# ========================================

output "scheduler_jobs" {
  description = "Cloud Scheduler job names"
  value       = module.scheduler.scheduler_job_names
}

# ========================================
# PUBSUB OUTPUTS
# ========================================

output "pubsub_topics" {
  description = "Pub/Sub topic names"
  value       = module.pubsub.topic_names
}

# ========================================
# MONITORING OUTPUTS
# ========================================

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "alert_policies" {
  description = "Alert policy names (if monitoring enabled)"
  value       = var.enable_monitoring ? module.monitoring[0].alert_policy_names : []
}

# ========================================
# DEPLOYMENT SUMMARY
# ========================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    project     = var.project_id
    environment = var.environment
    region      = var.region
    datasets    = 4
    functions   = length(module.cloud_functions.function_names)
    topics      = length(module.pubsub.topic_names)
    jobs        = length(module.scheduler.scheduler_job_names)
  }
}
