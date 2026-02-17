variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Functions"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string
}

variable "runtime" {
  description = "Python runtime version"
  type        = string
}

variable "memory" {
  description = "Memory allocation in MB"
  type        = number
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
}

variable "service_account_email" {
  description = "Service account email for functions"
  type        = string
}

variable "invoker_service_account_email" {
  description = "Service account email allowed to invoke function HTTP endpoints"
  type        = string
}

variable "functions_source_bucket" {
  description = "GCS bucket for function source code"
  type        = string
}

variable "bronze_dataset_id" {
  description = "Bronze dataset ID"
  type        = string
}

variable "silver_dataset_id" {
  description = "Silver dataset ID"
  type        = string
}

variable "gold_dataset_id" {
  description = "Gold dataset ID"
  type        = string
}

variable "quality_dataset_id" {
  description = "Quality dataset ID"
  type        = string
}

variable "enable_ml_snapshots" {
  description = "Enable ML snapshot function"
  type        = bool
  default     = true
}

variable "enable_quality_checks" {
  description = "Enable quality check function"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to functions"
  type        = map(string)
  default     = {}
}
