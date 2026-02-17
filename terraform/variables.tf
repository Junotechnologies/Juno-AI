# ========================================
# PROJECT CONFIGURATION
# ========================================

variable "project_id" {
  description = "GCP Project ID (e.g., junoplus-dev, juno-9dfb6)"
  type        = string

  validation {
    condition     = can(regex("^(junoplus-(dev|prod|staging)|juno-[a-z0-9]+)$", var.project_id))
    error_message = "Project ID must follow pattern: junoplus-{dev|prod|staging} or juno-{random}."
  }
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be one of: dev, prod, staging."
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "Region must be a valid GCP region (e.g., us-central1)."
  }
}

# ========================================
# BIGQUERY CONFIGURATION
# ========================================

variable "bq_location" {
  description = "BigQuery dataset location (must be multi-region: US, EU, or specific region)"
  type        = string
  default     = "US"
}

variable "bq_delete_protection" {
  description = "Enable deletion protection on BigQuery datasets"
  type        = bool
  default     = true
}

variable "bq_bronze_dataset_id" {
  description = "Bronze layer dataset ID for raw data"
  type        = string
  default     = "junoplus_analytics"
}

variable "bq_silver_dataset_id" {
  description = "Silver layer dataset ID for curated data"
  type        = string
  default     = "junoplus_analytics_silver"
}

variable "bq_gold_dataset_id" {
  description = "Gold layer dataset ID for analytics"
  type        = string
  default     = "junoplus_analytics_gold"
}

variable "bq_quality_dataset_id" {
  description = "Quality layer dataset ID for monitoring"
  type        = string
  default     = "junoplus_analytics_quality"
}

# ========================================
# CLOUD FUNCTIONS CONFIGURATION
# ========================================

variable "functions_runtime" {
  description = "Cloud Functions Python runtime version"
  type        = string
  default     = "python311"

  validation {
    condition     = contains(["python39", "python310", "python311", "python312"], var.functions_runtime)
    error_message = "Runtime must be a supported Python version."
  }
}

variable "functions_memory" {
  description = "Memory allocation for Cloud Functions (in MB)"
  type        = number
  default     = 512

  validation {
    condition     = contains([128, 256, 512, 1024, 2048, 4096, 8192], var.functions_memory)
    error_message = "Memory must be one of: 128, 256, 512, 1024, 2048, 4096, 8192."
  }
}

variable "functions_timeout" {
  description = "Cloud Functions timeout in seconds"
  type        = number
  default     = 540

  validation {
    condition     = var.functions_timeout >= 60 && var.functions_timeout <= 540
    error_message = "Timeout must be between 60 and 540 seconds."
  }
}

# ========================================
# CLOUD SCHEDULER CONFIGURATION
# ========================================

variable "scheduler_timezone" {
  description = "Timezone for Cloud Scheduler jobs"
  type        = string
  default     = "UTC"
}

variable "refresh_silver_cron" {
  description = "Cron schedule for silver layer refresh"
  type        = string
  default     = "0 2 * * *" # Daily at 2 AM UTC
}

variable "refresh_gold_cron" {
  description = "Cron schedule for gold layer refresh"
  type        = string
  default     = "0 3 * * 0" # Weekly on Sunday at 3 AM UTC
}

variable "quality_check_cron" {
  description = "Cron schedule for quality checks"
  type        = string
  default     = "0 * * * *" # Hourly
}

variable "ml_snapshot_cron" {
  description = "Cron schedule for ML snapshot creation"
  type        = string
  default     = "0 4 * * 1" # Weekly on Monday at 4 AM UTC
}

# ========================================
# FIREBASE CONFIGURATION
# ========================================

variable "firebase_project_id" {
  description = "Firebase project ID (usually same as GCP project)"
  type        = string
  default     = ""
}

variable "firestore_location" {
  description = "Firestore location (must match when creating database)"
  type        = string
  default     = "nam5" # North America
}

# ========================================
# LABELS & TAGGING
# ========================================

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "juno-analytics"
  }
}

# ========================================
# SECURITY & IAM
# ========================================

variable "service_account_roles" {
  description = "IAM roles for Cloud Functions service account"
  type        = list(string)
  default = [
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/pubsub.publisher",
    "roles/logging.logWriter",
    "roles/storage.objectViewer",
    "roles/secretmanager.secretAccessor",
    "roles/datastore.user",
  ]
}

# ========================================
# ALERTING & MONITORING
# ========================================

variable "notification_email" {
  description = "Email for alerts and notifications (stored in Secret Manager)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable Cloud Monitoring and logging"
  type        = bool
  default     = true
}

# ========================================
# FEATURE FLAGS
# ========================================

variable "enable_ml_snapshots" {
  description = "Enable ML snapshot Cloud Function deployment"
  type        = bool
  default     = true
}

variable "enable_quality_checks" {
  description = "Enable quality check Cloud Function deployment"
  type        = bool
  default     = true
}
