variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string
}

variable "notification_email_secret" {
  description = "Email address for notifications (optional)"
  type        = string
  sensitive   = true
  default     = null
}

variable "cloud_function_names" {
  description = "List of Cloud Function names to monitor"
  type        = list(string)
  default     = []
}

variable "dataset_ids" {
  description = "List of BigQuery dataset IDs to monitor"
  type        = list(string)
  default     = []
}
