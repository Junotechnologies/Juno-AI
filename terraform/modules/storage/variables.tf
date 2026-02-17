variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for buckets"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string
}

variable "labels" {
  description = "Labels to apply to buckets"
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "Service account email for bucket access"
  type        = string
}
