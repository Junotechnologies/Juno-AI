# ========================================
# JUNO ANALYTICS INFRASTRUCTURE
# ========================================
# This is the main entry point for the Terraform configuration.
# It calls the modules defined in the modules/ directory.

# ========================================
# DATA SOURCES
# ========================================

# Fetch the default compute service account
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# Fetch project information
data "google_project" "project" {
  project_id = var.project_id
}

# ========================================
# IAM MODULE
# ========================================

module "iam" {
  source = "./modules/iam"

  project_id    = var.project_id
  environment   = var.environment
  service_roles = var.service_account_roles
  labels        = var.labels
}

# ========================================
# BIGQUERY MODULE
# ========================================

module "bigquery" {
  source = "./modules/bigquery"

  project_id            = var.project_id
  location              = var.bq_location
  environment           = var.environment
  bronze_dataset_id     = var.bq_bronze_dataset_id
  silver_dataset_id     = var.bq_silver_dataset_id
  gold_dataset_id       = var.bq_gold_dataset_id
  quality_dataset_id    = var.bq_quality_dataset_id
  delete_protection     = var.bq_delete_protection
  labels                = var.labels
  service_account_email = module.iam.service_account_email
}

# ========================================
# CLOUD STORAGE MODULE
# ========================================

module "storage" {
  source = "./modules/storage"

  project_id            = var.project_id
  region                = var.region
  environment           = var.environment
  labels                = var.labels
  service_account_email = module.iam.service_account_email
}

# ========================================
# CLOUD FUNCTIONS MODULE
# ========================================

module "cloud_functions" {
  source = "./modules/cloud_functions"

  project_id                    = var.project_id
  region                        = var.region
  environment                   = var.environment
  runtime                       = var.functions_runtime
  memory                        = var.functions_memory
  timeout                       = var.functions_timeout
  service_account_email         = module.iam.service_account_email
  invoker_service_account_email = module.iam.service_account_email
  functions_source_bucket       = module.storage.functions_bucket_name
  enable_ml_snapshots           = var.enable_ml_snapshots
  enable_quality_checks         = var.enable_quality_checks
  labels                        = var.labels

  # Pass BigQuery dataset IDs
  bronze_dataset_id  = module.bigquery.bronze_dataset_id
  silver_dataset_id  = module.bigquery.silver_dataset_id
  gold_dataset_id    = module.bigquery.gold_dataset_id
  quality_dataset_id = module.bigquery.quality_dataset_id
}

# ========================================
# CLOUD SCHEDULER MODULE
# ========================================

module "scheduler" {
  source = "./modules/scheduler"

  project_id            = var.project_id
  region                = var.region
  timezone              = var.scheduler_timezone
  environment           = var.environment
  refresh_silver_cron   = var.refresh_silver_cron
  refresh_gold_cron     = var.refresh_gold_cron
  quality_check_cron    = var.quality_check_cron
  ml_snapshot_cron      = var.ml_snapshot_cron
  service_account_email = module.iam.service_account_email
  enable_quality_checks = var.enable_quality_checks
  enable_ml_snapshots   = var.enable_ml_snapshots

  # Cloud Function URLs
  refresh_silver_url = module.cloud_functions.refresh_silver_url
  refresh_gold_url   = module.cloud_functions.refresh_gold_url
  quality_check_url  = module.cloud_functions.quality_check_url
  ml_snapshot_url    = module.cloud_functions.ml_snapshot_url
}

# ========================================
# SCHEDULER SERVICE AGENT PERMISSIONS
# ========================================

resource "google_service_account_iam_member" "scheduler_token_creator" {
  service_account_id = module.iam.service_account_name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "scheduler_service_account_user" {
  service_account_id = module.iam.service_account_name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

# ========================================
# PUBSUB MODULE
# ========================================

module "pubsub" {
  source = "./modules/pubsub"

  project_id            = var.project_id
  environment           = var.environment
  labels                = var.labels
  service_account_email = module.iam.service_account_email
}

# ========================================
# MONITORING MODULE (OPTIONAL)
# ========================================

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  project_id                = var.project_id
  environment               = var.environment
  notification_email_secret = var.notification_email != "" ? var.notification_email : null

  # Resources to monitor
  cloud_function_names = module.cloud_functions.function_names
  dataset_ids = [
    module.bigquery.bronze_dataset_id,
    module.bigquery.silver_dataset_id,
    module.bigquery.gold_dataset_id,
    module.bigquery.quality_dataset_id
  ]
}
