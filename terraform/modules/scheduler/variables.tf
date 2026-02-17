variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Scheduler"
  type        = string
}

variable "timezone" {
  description = "Timezone for scheduler jobs"
  type        = string
  default     = "UTC"
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string
}

variable "refresh_silver_cron" {
  description = "Cron schedule for silver layer refresh"
  type        = string
}

variable "refresh_gold_cron" {
  description = "Cron schedule for gold layer refresh"
  type        = string
}

variable "quality_check_cron" {
  description = "Cron schedule for quality checks"
  type        = string
}

variable "ml_snapshot_cron" {
  description = "Cron schedule for ML snapshot creation"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for authentication"
  type        = string
}

variable "refresh_silver_url" {
  description = "Refresh silver function URL"
  type        = string
}

variable "refresh_gold_url" {
  description = "Refresh gold function URL"
  type        = string
}

variable "quality_check_url" {
  description = "Quality check function URL"
  type        = string
  default     = ""
}

variable "ml_snapshot_url" {
  description = "ML snapshot function URL"
  type        = string
  default     = ""
}

variable "enable_quality_checks" {
  description = "Enable quality check scheduler job"
  type        = bool
  default     = true
}

variable "enable_ml_snapshots" {
  description = "Enable ML snapshot scheduler job"
  type        = bool
  default     = true
}
