variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "location" {
  description = "BigQuery dataset location"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string
}

variable "bronze_dataset_id" {
  description = "Bronze dataset ID base name"
  type        = string
}

variable "silver_dataset_id" {
  description = "Silver dataset ID base name"
  type        = string
}

variable "gold_dataset_id" {
  description = "Gold dataset ID base name"
  type        = string
}

variable "quality_dataset_id" {
  description = "Quality dataset ID base name"
  type        = string
}

variable "delete_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to datasets"
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "Service account email for dataset access"
  type        = string
}
