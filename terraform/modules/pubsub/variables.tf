variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string
}

variable "labels" {
  description = "Labels to apply to Pub/Sub resources"
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "Service account email for Pub/Sub access"
  type        = string
}
