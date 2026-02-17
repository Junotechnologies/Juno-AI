terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # GCS Backend - stores state file in Google Cloud Storage
  # Configure bucket/prefix via: terraform init -backend-config=environments/<backend-file>.tfvars
  backend "gcs" {}
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Configure the Google Cloud Beta Provider (for features still in beta)
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
